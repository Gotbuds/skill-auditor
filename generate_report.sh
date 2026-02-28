#!/bin/bash
# Report Generator - Creates detailed audit report

set -e

RESULTS_DIR="$1"
SKILL_NAME="$2"
SKILL_PATH="$3"

if [ -z "$RESULTS_DIR" ] || [ -z "$SKILL_NAME" ]; then
    echo "Usage: $0 <results-dir> <skill-name> [skill-path]"
    exit 1
fi

REPORT_FILE="$RESULTS_DIR/audit_report.md"

# Read summary
SUMMARY=$(cat "$RESULTS_DIR/summary.txt" 2>/dev/null || echo "No summary available")

# Count files analyzed
if [ -n "$SKILL_PATH" ] && [ -d "$SKILL_PATH" ]; then
    FILE_COUNT=$(find "$SKILL_PATH" -type f | wc -l)
else
    FILE_COUNT="Unknown"
fi

# Get risk rating from summary
RATING=$(grep "Risk Rating:" "$RESULTS_DIR/summary.txt" | cut -d: -f2 | xargs || echo "Unknown")

# Generate report
cat > "$REPORT_FILE" <<EOF
# 🛡️ SKILL AUDIT REPORT

**Skill:** $SKILL_NAME
**Scanned:** $(date)
**Files Analyzed:** $FILE_COUNT
**Risk Level:** $RATING

---

## Executive Summary

EOF

# Add findings summary
if grep -q "🚨 CRITICAL" "$RESULTS_DIR"/*.txt 2>/dev/null; then
    cat >> "$REPORT_FILE" <<EOF
This skill contains **CRITICAL SECURITY ISSUES** and should NOT be installed.

EOF
elif grep -q "⚠️ HIGH" "$RESULTS_DIR"/*.txt 2>/dev/null; then
    cat >> "$REPORT_FILE" <<EOF
This skill has **significant security concerns**. Review findings carefully before installing.

EOF
elif grep -q "🔶 MEDIUM" "$RESULTS_DIR"/*.txt 2>/dev/null; then
    cat >> "$REPORT_FILE" <<EOF
This skill has **minor security concerns**. Proceed with caution.

EOF
else
    cat >> "$REPORT_FILE" <<EOF
This skill appears **safe to install** with no security issues detected.

EOF
fi

cat >> "$REPORT_FILE" <<EOF
---

## Detailed Findings

EOF

# Add each check's findings
CHECKS=(
    "malware_detection.txt:Malware Detection"
    "prompt_injection.txt:Prompt Injection Analysis"
    "credential_exposure.txt:Credential Exposure"
    "network_calls.txt:Network Call Analysis"
    "permissions.txt:Permission Scope Review"
    "dependencies.txt:Dependency Vulnerabilities"
    "obfuscation.txt:Obfuscation Detection"
    "social_engineering.txt:Social Engineering Analysis"
)

for check in "${CHECKS[@]}"; do
    CHECK_FILE=$(echo "$check" | cut -d: -f1)
    CHECK_NAME=$(echo "$check" | cut -d: -f2)

    if [ -f "$RESULTS_DIR/$CHECK_FILE" ]; then
        # Check if there are findings
        if grep -qE "(🚨|⚠️|🔶|🔹|❌)" "$RESULTS_DIR/$CHECK_FILE" 2>/dev/null; then
            cat >> "$REPORT_FILE" <<EOF

### $CHECK_NAME: ❌ ISSUES FOUND

EOF
            # Add findings (skip headers)
            grep -E "(🚨|⚠️|🔶|🔹|CRITICAL|HIGH|MEDIUM|LOW)" "$RESULTS_DIR/$CHECK_FILE" >> "$REPORT_FILE"
        else
            cat >> "$REPORT_FILE" <<EOF

### $CHECK_NAME: ✅ PASS

No issues detected.

EOF
        fi
    fi
done

# Add recommendation
cat >> "$REPORT_FILE" <<EOF

---

## Recommendation

EOF

case "$RATING" in
    *"DANGER"*)
        cat >> "$REPORT_FILE" <<EOF
🚨 **DO NOT INSTALL**

This skill contains critical security vulnerabilities or malicious code.
Installing this skill puts your system and data at serious risk.
EOF
        ;;
    *"WARNING"*)
        cat >> "$REPORT_FILE" <<EOF
⚠️ **INSTALL WITH CAUTION**

This skill has significant security concerns. Only install if you:
- Understand the risks
- Trust the source
- Have reviewed all findings above

Consider finding an alternative skill that doesn't have these issues.
EOF
        ;;
    *"CAUTION"*)
        cat >> "$REPORT_FILE" <<EOF
🟡 **PROCEED CAREFULLY**

This skill has minor security concerns. You may install it, but:
- Review the findings above
- Monitor the skill's behavior after installation
- Remove if you notice anything suspicious
EOF
        ;;
    *"SAFE"*)
        cat >> "$REPORT_FILE" <<EOF
🟢 **SAFE TO INSTALL**

No security issues were detected in this skill.
You can install with confidence.

Note: This audit is not a guarantee. Always monitor installed skills.
EOF
        ;;
esac

cat >> "$REPORT_FILE" <<EOF

---

## What This Skill Can Access

Based on the audit, if installed, this skill would have access to:

EOF

# Check what access was detected
if grep -q "network_calls" "$RESULTS_DIR"/*.txt 2>/dev/null && grep -q "External URL" "$RESULTS_DIR/network_calls.txt" 2>/dev/null; then
    echo "- 🌐 External network connections" >> "$REPORT_FILE"
fi

if grep -q "file system" "$RESULTS_DIR"/*.txt 2>/dev/null; then
    echo "- 📁 File system access" >> "$REPORT_FILE"
fi

if grep -q "environment" "$RESULTS_DIR"/*.txt 2>/dev/null; then
    echo "- 🔧 Environment variables" >> "$REPORT_FILE"
fi

# Default if nothing specific
if [ $(wc -l < "$REPORT_FILE") -eq $(grep -n "What This Skill Can Access" "$REPORT_FILE" | cut -d: -f1) ]; then
    cat >> "$REPORT_FILE" <<EOF
- Standard OpenClaw agent capabilities
- May have additional access not detected by this audit

EOF
fi

cat >> "$REPORT_FILE" <<EOF

---

## Full Details

For complete scan output, see:
- $(ls "$RESULTS_DIR"/*.txt | xargs -n1 basename | tr '\n' ' ')

---

**Audited by:** Ronald Skill Auditor v1.0.0 🔍
**Report generated:** $(date)
**Results directory:** $RESULTS_DIR

---

*"If you're not auditing, you're not safe."*
EOF

echo "Report generated: $REPORT_FILE"
