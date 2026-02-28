#!/bin/bash
# Social Engineering Detection Check
# Detects manipulation and phishing patterns

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== SOCIAL ENGINEERING CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# Urgency patterns (specific manipulation, not common words)
URGENCY_PATTERNS=(
    "act (now|immediately|today)"
    "(hurry|urgent).*?(before|limited|expire)"
    "limited time (offer|deal|window)"
    "before it'?s too late"
    "don'?t (wait|delay|hesitate)"
    "(must|have to|need to) (act|respond|reply) (now|immediately|today)"
    "offer (expires|ends) (today|soon|in.*hours)"
)

# Authority patterns (only flag deceptive claims, not legitimate security tools)
AUTHORITY_PATTERNS=(
    "officially (verified|approved|certified) by"
    "(we are|this is) (official|verified|authorized)"
    "(endorsed|approved) by (openclaw|openai|anthropic)"
    "certified (safe|secure|trusted)"
)

# Threat patterns (must be in threat context, not general documentation)
THREAT_PATTERNS=(
    "your (account|access) (will be|has been) (suspended|locked|terminated|deleted)"
    "(suspended|locked|terminated) (your|this) account"
    "unauthorized (access|login|activity) detected"
    "suspicious activity on your account"
    "account (expired|compromised)"
    "security breach"
)

# Credential request patterns (must be in request context, not documentation)
CREDENTIAL_PATTERNS=(
    "please (provide|enter|give|send) (your )?(password|pin|code|key|credential)"
    "we need your (password|pin|credential|key)"
    "verify your (password|pin|credential)"
    "confirm your (password|pin|credential)"
    "enter your (password|pin|credential|api key|token)"
    "provide (your )?(api key|token|credential)"
    "what is (your )?(password|pin)"
)

# Check all markdown files
MD_FILES=$(find "$SKILL_PATH" -name "*.md" -type f 2>/dev/null)

for file in $MD_FILES; do
    RELATIVE_PATH=${file#$SKILL_PATH/}
    CONTENT=$(cat "$file" 2>/dev/null)

    # Urgency check
    for pattern in "${URGENCY_PATTERNS[@]}"; do
        if echo "$CONTENT" | grep -qiE "$pattern"; then
            echo "🔶 MEDIUM: Urgency language in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done

    # Authority check
    for pattern in "${AUTHORITY_PATTERNS[@]}"; do
        if echo "$CONTENT" | grep -qiE "$pattern"; then
            echo "🔹 LOW: Authority claim in $RELATIVE_PATH: $pattern"
            # Only flag if combined with other indicators
        fi
    done

    # Threat check
    for pattern in "${THREAT_PATTERNS[@]}"; do
        if echo "$CONTENT" | grep -qiE "$pattern"; then
            echo "⚠️ HIGH: Threat language in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done

    # Credential request check
    for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
        if echo "$CONTENT" | grep -qiE "$pattern"; then
            echo "⚠️ HIGH: Credential request pattern in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done
done

# Check for misleading descriptions
if [ -f "$SKILL_PATH/SKILL.md" ]; then
    DESCRIPTION=$(grep -A1 "^description:" "$SKILL_PATH/SKILL.md" | head -1)

    # Check if description doesn't match actual functionality
    # This is a simple heuristic
    if echo "$DESCRIPTION" | grep -qiE "(free|win|prize|reward|bonus|gift)"; then
        echo "⚠️ HIGH: Suspicious description (too good to be true)"
        FOUND=1
    fi
fi

# Check for fake verification claims
if grep -rqE "(verified|official|approved|trusted).*(skill|plugin|extension)" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: Unverified trust claims"
    FOUND=1
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No social engineering patterns detected"
else
    echo "⚠️ WARNING: Social engineering patterns detected"
fi

exit $FOUND
