#!/bin/bash
# Installation verification script
# Run this after installing to verify everything works

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🛡️  SKILL AUDITOR INSTALLATION VERIFICATION           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if skill is installed
if [ ! -d ~/.openclaw/skills/skill-auditor ]; then
    echo "❌ Skill not installed at ~/.openclaw/skills/skill-auditor"
    echo ""
    echo "To install:"
    echo "  clawhub install skill-auditor"
    exit 1
fi

echo "✅ Skill installed at: ~/.openclaw/skills/skill-auditor"
echo ""

# Check if scripts are executable
if [ -x ~/.openclaw/skills/skill-auditor/scan_skill.sh ]; then
    echo "✅ Scanner script is executable"
else
    echo "⚠️  Scanner script not executable - fixing..."
    chmod +x ~/.openclaw/skills/skill-auditor/*.sh
    chmod +x ~/.openclaw/skills/skill-auditor/checks/*.sh
fi

# Run test scan
echo ""
echo "Running test scan on self..."
echo ""

TEMP_DIR=$(mktemp -d)
~/.openclaw/skills/skill-auditor/scan_skill.sh ~/.openclaw/skills/skill-auditor "$TEMP_DIR" 2>&1 | tail -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$TEMP_DIR/summary.txt" ]; then
    echo "✅ Test scan completed successfully"
    echo ""
    echo "Skill Auditor is ready to use!"
    echo ""
    echo "Try saying to your agent:"
    echo "  'Audit the [skill-name] skill before I install it'"
else
    echo "❌ Test scan failed"
    echo "Check the output above for errors"
fi

rm -rf "$TEMP_DIR"
