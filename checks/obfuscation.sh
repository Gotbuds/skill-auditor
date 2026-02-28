#!/bin/bash
# Obfuscation Detection Check
# Detects encoded and obfuscated code

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== OBFUSCATION DETECTION CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# Base64 patterns
if grep -rqE "(base64|atob|btoa|Buffer\.from.*base64)" "$SKILL_PATH" 2>/dev/null; then
    echo "⚠️ HIGH: Base64 encoding/decoding detected"
    FOUND=1
fi

# Large base64 blobs (potential payload)
if grep -rqE "[A-Za-z0-9+/]{100,}={0,2}" "$SKILL_PATH" --include="*.md" --include="*.js" 2>/dev/null; then
    echo "⚠️ HIGH: Large encoded blobs detected"
    FOUND=1
fi

# Hex encoding
if grep -rqE "\\\x[0-9a-fA-F]{2}" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: Hex encoding detected"
    FOUND=1
fi

# Unicode escapes
if grep -rqE "\\\u[0-9a-fA-F]{4}" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: Unicode escapes detected"
    FOUND=1
fi

# Zero-width characters (stealthy)
if grep -rqP "[\x{200B}-\x{200D}\x{FEFF}]" "$SKILL_PATH" 2>/dev/null; then
    echo "🚨 CRITICAL: Zero-width unicode characters detected (hidden content)"
    FOUND=1
fi

# eval() and Function()
if grep -rqE "(eval|Function)\s*\(" "$SKILL_PATH" 2>/dev/null; then
    echo "⚠️ HIGH: eval() or Function() usage detected"
    FOUND=1
fi

# String.fromCharCode (obfuscation technique)
if grep -rqE "String\.fromCharCode" "$SKILL_PATH" 2>/dev/null; then
    echo "⚠️ HIGH: String.fromCharCode detected (obfuscation)"
    FOUND=1
fi

# Excessive string concatenation
if grep -rqE "'[a-z]'\s*\+\s*'[a-z]'" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: String concatenation detected (potential obfuscation)"
    FOUND=1
fi

# Minified JavaScript (single line)
JS_FILES=$(find "$SKILL_PATH" -name "*.js" -type f 2>/dev/null)
for js in $JS_FILES; do
    LINES=$(wc -l < "$js")
    CHARS=$(wc -c < "$js")
    if [ "$LINES" -eq 1 ] && [ "$CHARS" -gt 500 ]; then
        echo "🔶 MEDIUM: Minified JavaScript detected: ${js#$SKILL_PATH/}"
        FOUND=1
    fi
done

# ROT13 and other simple ciphers
if grep -rqE "rot13|ROT13|cipher|decode|decrypt" "$SKILL_PATH" 2>/dev/null; then
    echo "🔶 MEDIUM: Cipher-related terms detected"
    FOUND=1
fi

# Hidden in comments
if grep -rqE "<!--.*-->" "$SKILL_PATH" --include="*.md" 2>/dev/null; then
    # Check if comments contain suspicious content
    if grep -rqE "<!--.*(eval|exec|system|http|api).*-->" "$SKILL_PATH" 2>/dev/null; then
        echo "⚠️ HIGH: Suspicious content in HTML comments"
        FOUND=1
    fi
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No obfuscation detected"
else
    echo "⚠️ WARNING: Obfuscation techniques detected"
fi

exit $FOUND
