#!/bin/bash
# Credential Exposure Detection Check
# Detects hardcoded credentials, API keys, and secrets

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== CREDENTIAL EXPOSURE CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# API key patterns
API_PATTERNS=(
    # OpenAI
    "sk-[a-zA-Z0-9]{20,}"
    "sk-proj-[a-zA-Z0-9]{20,}"

    # Slack
    "xox[baprs]-[a-zA-Z0-9\-]{10,}"

    # GitHub
    "ghp_[a-zA-Z0-9]{36}"
    "github_pat_[a-zA-Z0-9_]{22,}"
    "gho_[a-zA-Z0-9]{36}"
    "ghu_[a-zA-Z0-9]{36}"
    "ghs_[a-zA-Z0-9]{36}"
    "ghr_[a-zA-Z0-9]{36}"

    # AWS
    "AKIA[A-Z0-9]{16}"
    "aws_access_key_id\s*=\s*AKIA"
    "aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}"

    # Google
    "ya29\.[a-zA-Z0-9_\-]{20,}"
    "AIza[a-zA-Z0-9_\-]{35}"

    # Stripe
    "sk_live_[a-zA-Z0-9]{24,}"
    "sk_test_[a-zA-Z0-9]{24,}"
    "rk_live_[a-zA-Z0-9]{24,}"

    # Generic
    "api[_-]?key\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]"
    "secret[_-]?key\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]"
    "access[_-]?token\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]"
    "bearer\s+[a-zA-Z0-9_\-]{20,}"
)

# Password patterns
PASSWORD_PATTERNS=(
    "password\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "passwd\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    "pwd\s*[:=]\s*['\"][^'\"]{8,}['\"]"
)

# Private key patterns
KEY_PATTERNS=(
    "-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----"
    "-----BEGIN PGP PRIVATE KEY BLOCK-----"
    "ssh-rsa [A-Za-z0-9+/=]+"
    "ssh-ed25519 [A-Za-z0-9+/=]+"
)

# Database connection strings
DB_PATTERNS=(
    "mongodb(\+srv)?://[^:]+:[^@]+@"
    "mysql://[^:]+:[^@]+@"
    "postgres(ql)?://[^:]+:[^@]+@"
    "redis://[^:]*:[^@]+@"
)

# Check all files
ALL_FILES=$(find "$SKILL_PATH" -type f ! -path "*/\.git/*" 2>/dev/null)

for file in $ALL_FILES; do
    # Skip binary files
    if file "$file" 2>/dev/null | grep -q "binary"; then
        continue
    fi

    RELATIVE_PATH=${file#$SKILL_PATH/}

    # API keys
    for pattern in "${API_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "🚨 CRITICAL: API key pattern found in: $RELATIVE_PATH"
            grep -oE "$pattern" "$file" | head -1 | sed 's/\(.\{20\}\).*/\1.../'
            FOUND=1
        fi
    done

    # Passwords
    for pattern in "${PASSWORD_PATTERNS[@]}"; do
        if grep -qiE "$pattern" "$file" 2>/dev/null; then
            echo "🚨 CRITICAL: Password pattern found in: $RELATIVE_PATH"
            FOUND=1
        fi
    done

    # Private keys
    for pattern in "${KEY_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "🚨 CRITICAL: Private key found in: $RELATIVE_PATH"
            FOUND=1
        fi
    done

    # Database strings
    for pattern in "${DB_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "⚠️ HIGH: Database connection string in: $RELATIVE_PATH"
            FOUND=1
        fi
    done
done

# Check for .env files specifically
ENV_FILES=$(find "$SKILL_PATH" -name ".env*" -type f 2>/dev/null)
if [ -n "$ENV_FILES" ]; then
    echo "⚠️ HIGH: .env file(s) found:"
    echo "$ENV_FILES"
    echo "These should NOT be included in skills."
    FOUND=1
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No exposed credentials detected"
else
    echo "❌ FAIL: Credential exposure detected"
fi

exit $FOUND
