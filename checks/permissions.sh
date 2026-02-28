#!/bin/bash
# Permission Scope Review Check
# Detects excessive file access and dangerous commands

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== PERMISSION SCOPE CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# Sensitive paths that skills shouldn't access
SENSITIVE_PATHS=(
    "\.ssh/"
    "\.gnupg/"
    "\.config/"
    "\.aws/"
    "\.env"
    "\.bash_history"
    "\.zsh_history"
    "\.mysql_history"
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
    "/root/"
    "Library/Keychains/"
    "\.Trash/"
)

# Dangerous command patterns
DANGEROUS_COMMANDS=(
    "sudo\s+"
    "su\s+"
    "rm\s+-rf\s+/"
    "rm\s+-rf\s+~"
    "chmod\s+(777|666)"
    "chown\s+.*:"
    "mkfs"
    "dd\s+if="
    ">\s*/dev/sd"
    ">\s*/dev/hd"
)

# Code execution patterns
EXEC_PATTERNS=(
    "eval\s*\("
    "exec\s*\("
    "subprocess\s*\."
    "Popen\s*\("
    "child_process"
    "\.spawn\s*\("
    "\.exec\s*\("
    "Function\s*\("
)

# File system access patterns (specific file names, not generic words)
FILE_ACCESS=(
    "\.ssh/id_rsa"
    "\.ssh/id_ed25519"
    "id_rsa"
    "id_ed25519"
    "\.pem$"
    "\.key$"
    "\.p12$"
    "\.pfx$"
    "credentials\.json"
    "credentials\.yml"
    "credentials\.yaml"
    "secrets\.json"
    "secrets\.yml"
    "secrets\.yaml"
    "\.env$"
    "\.env\."
)

# Check all files
ALL_FILES=$(find "$SKILL_PATH" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.js" -o -name "*.py" \) 2>/dev/null)

for file in $ALL_FILES; do
    RELATIVE_PATH=${file#$SKILL_PATH/}

    # Check for sensitive path access
    for path in "${SENSITIVE_PATHS[@]}"; do
        if grep -qE "$path" "$file" 2>/dev/null; then
            echo "🚨 CRITICAL: Sensitive path access in $RELATIVE_PATH: $path"
            grep -n "$path" "$file" | head -1
            FOUND=1
        fi
    done

    # Check for dangerous commands
    for cmd in "${DANGEROUS_COMMANDS[@]}"; do
        if grep -qE "$cmd" "$file" 2>/dev/null; then
            echo "🚨 CRITICAL: Dangerous command in $RELATIVE_PATH: $cmd"
            FOUND=1
        fi
    done

    # Check for code execution
    for pattern in "${EXEC_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "⚠️ HIGH: Code execution pattern in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done

    # Check for file access patterns
    for pattern in "${FILE_ACCESS[@]}"; do
        if grep -qiE "$pattern" "$file" 2>/dev/null; then
            echo "⚠️ HIGH: Sensitive file pattern in $RELATIVE_PATH: $pattern"
            FOUND=1
        fi
    done
done

# Check for home directory access
if grep -rqE "~/|\\\$HOME|/home/|/Users/" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: Home directory access detected"
    FOUND=1
fi

# Check for environment variable access
if grep -rqE "\\\$[A-Z_]+|process\.env" "$SKILL_PATH" 2>/dev/null; then
    echo "🔹 LOW: Environment variable access detected (may be legitimate)"
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No excessive permissions detected"
else
    echo "❌ FAIL: Potentially dangerous permissions detected"
fi

exit $FOUND
