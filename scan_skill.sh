#!/bin/bash
# Main Scanner - Runs all security checks
# Usage: ./scan_skill.sh <skill-path> [output-dir]

# Don't exit on error - we want to continue running all checks
# set -e removed

SKILL_PATH="$1"
OUTPUT_DIR="$2"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <skill-path> [output-dir]"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create output directory
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(mktemp -d)
fi
mkdir -p "$OUTPUT_DIR"

# Get skill name
SKILL_NAME=$(basename "$SKILL_PATH")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║            🛡️  RONALD SKILL AUDITOR v1.1.0                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Skill: $SKILL_NAME"
echo "Path: $SKILL_PATH"
echo "Output: $OUTPUT_DIR"
echo "Started: $(date)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run all checks
CHECKS=(
    "malware_detection:Malware Detection"
    "prompt_injection:Prompt Injection"
    "credential_exposure:Credential Exposure"
    "network_calls:Network Analysis"
    "permissions:Permission Scope"
    "dependencies:Dependency Vulnerabilities"
    "obfuscation:Obfuscation Detection"
    "social_engineering:Social Engineering"
)

TOTAL_CRITICAL=0
TOTAL_HIGH=0
TOTAL_MEDIUM=0
TOTAL_LOW=0

for check in "${CHECKS[@]}"; do
    CHECK_SCRIPT=$(echo "$check" | cut -d: -f1)
    CHECK_NAME=$(echo "$check" | cut -d: -f2)

    echo "▶ Running: $CHECK_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    OUTPUT_FILE="$OUTPUT_DIR/${CHECK_SCRIPT}.txt"
    "$SCRIPT_DIR/checks/${CHECK_SCRIPT}.sh" "$SKILL_PATH" > "$OUTPUT_FILE" 2>&1
    CHECK_EXIT=$?

    # Count severities (handle multi-line output from grep)
    CRITICAL=$(grep -o "🚨 CRITICAL" "$OUTPUT_FILE" 2>/dev/null | wc -l || true)
    HIGH=$(grep -o "⚠️ HIGH" "$OUTPUT_FILE" 2>/dev/null | wc -l || true)
    MEDIUM=$(grep -o "🔶 MEDIUM" "$OUTPUT_FILE" 2>/dev/null | wc -l || true)
    LOW=$(grep -o "🔹 LOW" "$OUTPUT_FILE" 2>/dev/null | wc -l || true)

    # Ensure we have numbers
    CRITICAL=${CRITICAL:-0}
    HIGH=${HIGH:-0}
    MEDIUM=${MEDIUM:-0}
    LOW=${LOW:-0}

    TOTAL_CRITICAL=$((TOTAL_CRITICAL + CRITICAL))
    TOTAL_HIGH=$((TOTAL_HIGH + HIGH))
    TOTAL_MEDIUM=$((TOTAL_MEDIUM + MEDIUM))
    TOTAL_LOW=$((TOTAL_LOW + LOW))

    if [ $CHECK_EXIT -eq 0 ]; then
        echo "   Status: ✅ PASS"
    else
        echo "   Status: ❌ FAIL"
        echo "   Critical: $CRITICAL | High: $HIGH | Medium: $MEDIUM | Low: $LOW"
    fi
    echo ""
done

# Determine overall risk rating
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Findings:"
echo "  🚨 Critical: $TOTAL_CRITICAL"
echo "  ⚠️  High:     $TOTAL_HIGH"
echo "  🔶 Medium:   $TOTAL_MEDIUM"
echo "  🔹 Low:      $TOTAL_LOW"
echo ""

# Risk rating logic
if [ $TOTAL_CRITICAL -gt 0 ] || [ $TOTAL_HIGH -ge 2 ]; then
    RATING="🔴 DANGER"
    RATING_DESC="Do NOT install this skill"
elif [ $TOTAL_HIGH -eq 1 ] || [ $TOTAL_MEDIUM -ge 2 ]; then
    RATING="🟠 WARNING"
    RATING_DESC="Significant security concerns"
elif [ $TOTAL_MEDIUM -eq 1 ] || [ $TOTAL_LOW -ge 2 ]; then
    RATING="🟡 CAUTION"
    RATING_DESC="Minor concerns detected"
else
    RATING="🟢 SAFE"
    RATING_DESC="No security issues found"
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  OVERALL RISK: $RATING"
echo "║  $RATING_DESC"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Completed: $(date)"
echo "Results saved to: $OUTPUT_DIR"
echo ""

# Save summary
cat > "$OUTPUT_DIR/summary.txt" <<EOF
SKILL AUDIT SUMMARY
===================

Skill: $SKILL_NAME
Scanned: $(date)
Risk Rating: $RATING

Findings:
- Critical: $TOTAL_CRITICAL
- High: $TOTAL_HIGH
- Medium: $TOTAL_MEDIUM
- Low: $TOTAL_LOW

Recommendation: $RATING_DESC
EOF

# Exit with appropriate code
if [ $TOTAL_CRITICAL -gt 0 ]; then
    exit 2  # Critical
elif [ $TOTAL_HIGH -gt 0 ]; then
    exit 1  # Warning
else
    exit 0  # Safe
fi
