#!/bin/bash
# Prompt Injection Detection Check
# Detects direct, indirect, and multi-turn injection attempts

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== PROMPT INJECTION CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# Direct injection patterns
DIRECT_PATTERNS=(
    "ignore.*previous"
    "ignore.*above"
    "disregard.*previous"
    "disregard.*above"
    "forget.*previous"
    "forget.*above"
    "you are now"
    "new instructions"
    "override"
    "bypass"
    "jailbreak"
    "developer mode"
    "debug mode"
    "enable all"
    "disable safety"
    "disable security"
    "no restrictions"
    "no limits"
)

# Indirect injection markers (specific patterns that indicate manipulation)
INDIRECT_PATTERNS=(
    "when you (see|read|process) .*(execute|run|perform)"
    "if you (encounter|find|see) .*(do|execute|run)"
    "hidden instructions (for|to|below)"
    "secret (command|instruction) (for|to)"
    "between the lines"
    "read carefully.*(then|and) (execute|do|run)"
    "important.*(hidden|secret|execute)"
)

# Role manipulation
ROLE_PATTERNS=(
    "you are (now|actually)"
    "pretend (you are|to be)"
    "act as (if|though)"
    "role.?play"
    "simulate"
    "impersonate"
)

# Check all markdown files
MD_FILES=$(find "$SKILL_PATH" -name "*.md" -type f 2>/dev/null)

for file in $MD_FILES; do
    echo "Checking: $file"

    # Direct injection
    for pattern in "${DIRECT_PATTERNS[@]}"; do
        if grep -iq "$pattern" "$file" 2>/dev/null; then
            MATCH=$(grep -i "$pattern" "$file" | head -1)
            echo "🚨 CRITICAL: Direct injection pattern: '$pattern'"
            echo "   Found: $MATCH"
            FOUND=1
        fi
    done

    # Indirect injection
    for pattern in "${INDIRECT_PATTERNS[@]}"; do
        if grep -iEq "$pattern" "$file" 2>/dev/null; then
            MATCH=$(grep -iE "$pattern" "$file" | head -1)
            echo "⚠️ HIGH: Indirect injection pattern: '$pattern'"
            echo "   Found: $MATCH"
            FOUND=1
        fi
    done

    # Role manipulation
    for pattern in "${ROLE_PATTERNS[@]}"; do
        if grep -iEq "$pattern" "$file" 2>/dev/null; then
            MATCH=$(grep -iE "$pattern" "$file" | head -1)
            echo "⚠️ HIGH: Role manipulation pattern: '$pattern'"
            echo "   Found: $MATCH"
            FOUND=1
        fi
    done
done

# Check script files for injection
SCRIPT_FILES=$(find "$SKILL_PATH" -type f \( -name "*.sh" -o -name "*.js" -o -name "*.py" \) 2>/dev/null)

for file in $SCRIPT_FILES; do
    # Look for injection in comments or strings
    if grep -iEq "(ignore|disregard|override|bypass|jailbreak)" "$file" 2>/dev/null; then
        echo "⚠️ HIGH: Injection-related terms in script: $file"
        grep -iEn "(ignore|disregard|override|bypass|jailbreak)" "$file" | head -3
        FOUND=1
    fi
done

# Check for obfuscated injection (base64)
if grep -rE "^[A-Za-z0-9+/]{40,}={0,2}$" "$SKILL_PATH" --include="*.md" 2>/dev/null; then
    echo "⚠️ HIGH: Potential base64 encoded content (could hide injection)"
    FOUND=1
fi

# Unicode obfuscation check
if grep -rP "[\x{200B}-\x{200D}\x{FEFF}]" "$SKILL_PATH" --include="*.md" 2>/dev/null; then
    echo "⚠️ HIGH: Zero-width unicode characters detected (obfuscation)"
    FOUND=1
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No prompt injection detected"
else
    echo "❌ FAIL: Prompt injection indicators detected"
fi

exit $FOUND
