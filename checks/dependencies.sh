#!/bin/bash
# Dependency Vulnerability Check
# Detects vulnerable and malicious npm packages

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path>"
    exit 1
fi

echo "=== DEPENDENCY VULNERABILITY CHECK ==="
echo "Scanning: $SKILL_PATH"
echo ""

FOUND=0

# Known malicious npm packages (subset)
MALICIOUS_PACKAGES=(
    "event-stream"
    "flatmap-stream"
    "lodash.template"
    "eslint-scope"
    "hack-team"
)

# Suspicious package patterns
SUSPICIOUS_PATTERNS=(
    "clipboardy"
    "keylogger"
    "screenshot"
    "puppeteer-core"
    "node-pty"
)

# Check for package.json
PACKAGE_JSON=$(find "$SKILL_PATH" -name "package.json" -type f 2>/dev/null)

if [ -z "$PACKAGE_JSON" ]; then
    echo "ℹ️  INFO: No package.json found"
    echo "✅ PASS: No npm dependencies"
    exit 0
fi

echo "Found package.json files:"
echo "$PACKAGE_JSON"
echo ""

# Check each package.json
for pkg in $PACKAGE_JSON; do
    RELATIVE_PATH=${pkg#$SKILL_PATH/}
    echo "Analyzing: $RELATIVE_PATH"

    # Check for malicious packages
    for mal_pkg in "${MALICIOUS_PACKAGES[@]}"; do
        if grep -q "\"$mal_pkg\"" "$pkg" 2>/dev/null; then
            echo "🚨 CRITICAL: Known malicious package: $mal_pkg"
            FOUND=1
        fi
    done

    # Check for suspicious packages
    for sus_pkg in "${SUSPICIOUS_PATTERNS[@]}"; do
        if grep -qi "\"$sus_pkg\"" "$pkg" 2>/dev/null; then
            echo "⚠️ HIGH: Suspicious package: $sus_pkg"
            FOUND=1
        fi
    done

    # Run npm audit if available
    PKG_DIR=$(dirname "$pkg")
    if command -v npm &> /dev/null && [ -f "$PKG_DIR/package-lock.json" ]; then
        echo "Running npm audit..."
        cd "$PKG_DIR"
        AUDIT_OUTPUT=$(npm audit --json 2>/dev/null || true)
        cd - > /dev/null

        CRITICAL=$(echo "$AUDIT_OUTPUT" | grep -o '"critical":[0-9]*' | grep -o '[0-9]*' || echo "0")
        HIGH=$(echo "$AUDIT_OUTPUT" | grep -o '"high":[0-9]*' | grep -o '[0-9]*' || echo "0")

        if [ "$CRITICAL" -gt 0 ]; then
            echo "🚨 CRITICAL: $CRITICAL critical vulnerabilities found"
            FOUND=1
        fi

        if [ "$HIGH" -gt 0 ]; then
            echo "⚠️ HIGH: $HIGH high vulnerabilities found"
            FOUND=1
        fi
    fi

    # Check for post-install scripts
    if grep -qE "(postinstall|preinstall)" "$pkg" 2>/dev/null; then
        echo "⚠️ HIGH: Post/pre-install scripts detected (review carefully)"
        FOUND=1
    fi

    # Check for binary dependencies
    if grep -qE "\.(node|dll|so|dylib)" "$pkg" 2>/dev/null; then
        echo "⚠️ HIGH: Binary dependencies detected"
        FOUND=1
    fi
done

# Check for package-lock.json (good practice)
LOCK_FILES=$(find "$SKILL_PATH" -name "package-lock.json" -type f 2>/dev/null)
if [ -z "$LOCK_FILES" ] && [ -n "$PACKAGE_JSON" ]; then
    echo "🔹 LOW: No package-lock.json found (dependencies not pinned)"
fi

# Summary
echo ""
if [ $FOUND -eq 0 ]; then
    echo "✅ PASS: No vulnerable dependencies detected"
else
    echo "❌ FAIL: Dependency vulnerabilities detected"
fi

exit $FOUND
