#!/bin/bash
# Network Call Analysis Check
# Detects external API calls, phone-home behavior, and data exfiltration

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== NETWORK CALL ANALYSIS ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0
NETWORK_CALLS=""

# HTTP/HTTPS patterns
HTTP_PATTERNS=(
    "https?://[^\\s\"']+"
    "api\.[a-z0-9\-]+\.[a-z]{2,}"
    "webhook\.[a-z0-9\-]+\.[a-z]{2,}"
)

# Known malicious/suspicious domains
MALICIOUS_DOMAINS=(
    "openclawcli"
    "\.xyz/"
    "\.tk/"
    "\.ml/"
    "\.ga/"
    "\.cf/"
    "ngrok\.io"
    "serveo\.net"
    "localtunnel\.me"
)

# Network call patterns in code
NETWORK_CODE_PATTERNS=(
    "curl\s+"
    "wget\s+"
    "fetch\s*\("
    "axios\.(get|post|put|delete|patch)"
    "request\.(get|post)"
    "\.fetch\("
    "XMLHttpRequest"
    "http\.get\("
    "http\.post\("
    "http\.request\("
    "net\.connect\("
    "socket\.(connect|send)"
)

# Check for network calls in code files only (not documentation)
CODE_FILES=$(find "$SKILL_PATH" -type f \( -name "*.sh" -o -name "*.js" -o -name "*.py" \) 2>/dev/null)

for file in $CODE_FILES; do
    RELATIVE_PATH=${file#$SKILL_PATH/}

    # Check for HTTP URLs in code
    URLS=$(grep -oE "https?://[^\\s\"')<>]+" "$file" 2>/dev/null || true)
    if [ -n "$URLS" ]; then
        while IFS= read -r url; do
            # Skip localhost and common safe domains
            if echo "$url" | grep -qE "(localhost|127\.0\.0\.1|example\.com)"; then
                echo "🔹 LOW: Local/example URL in $RELATIVE_PATH: $url"
            else
                NETWORK_CALLS="$NETWORK_CALLS\n$url ($RELATIVE_PATH)"
                echo "🔶 MEDIUM: External URL in code $RELATIVE_PATH: $url"
                FOUND=1
            fi
        done <<< "$URLS"
    fi

    # Check for network code patterns
    for pattern in "${NETWORK_CODE_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "🔶 MEDIUM: Network call pattern in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done
done

# Check for URLs in markdown (informational only, not flagged as findings)
MD_FILES=$(find "$SKILL_PATH" -type f -name "*.md" 2>/dev/null)
for file in $MD_FILES; do
    RELATIVE_PATH=${file#$SKILL_PATH/}
    URLS=$(grep -oE "https?://[^\\s\"')<>]+" "$file" 2>/dev/null || true)
    if [ -n "$URLS" ]; then
        while IFS= read -r url; do
            # Only flag suspicious domains in markdown
            for domain in "${MALICIOUS_DOMAINS[@]}"; do
                if echo "$url" | grep -qiE "$domain"; then
                    echo "⚠️ HIGH: Suspicious URL in $RELATIVE_PATH: $url"
                    FOUND=1
                fi
            done
        done <<< "$URLS"
    fi
done

# Check for suspicious domains
ALL_CONTENT=$(cat $(find "$SKILL_PATH" -type f ! -path "*/\.git/*" 2>/dev/null) 2>/dev/null || true)

for domain in "${MALICIOUS_DOMAINS[@]}"; do
    if echo "$ALL_CONTENT" | grep -qiE "$domain"; then
        echo "🚨 CRITICAL: Suspicious domain pattern: $domain"
        FOUND=1
    fi
done

# Check for POST/PUT requests (potential data exfiltration)
if grep -rqE "(POST|PUT|PATCH)\s+(http|/)" "$SKILL_PATH" 2>/dev/null; then
    echo "⚠️ HIGH: Data submission (POST/PUT) requests found"
    FOUND=1
fi

# Check for webhook URLs
if grep -rqE "webhook|hook\.slack|discord\.com/api/webhooks" "$SKILL_PATH" 2>/dev/null; then
    echo "⚠️ HIGH: Webhook URLs found (potential data exfiltration)"
    FOUND=1
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No suspicious network activity detected"
else
    echo "⚠️ WARNING: Network calls detected (review for legitimacy)"
fi

exit $FOUND
