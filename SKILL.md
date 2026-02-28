---
name: skill-auditor
description: Security scanner for OpenClaw skills. Detects malware, prompt injection, credential theft, data exfiltration, and suspicious behavior before installation. Use when installing skills from ClawHub, GitHub, or untrusted sources. Always audit before installing.
---

# 🛡️ Skill Auditor

## Overview

Scan OpenClaw skills for security risks BEFORE installation. Protects against:
- 🦠 Malware and malicious code (Atomic MacOS Stealer, etc.)
- 💉 Prompt injection attacks (direct, indirect, multi-turn)
- 🔑 Credential harvesting and theft
- 🌐 Data exfiltration and phone-home behavior
- 📁 Excessive file system access
- 📦 Vulnerable or malicious dependencies
- 🎭 Social engineering and manipulation
- 🧬 Obfuscated code (base64, unicode, etc.)

## When to Use

**ALWAYS use before installing skills from:**
- ClawHub (public marketplace)
- GitHub repositories
- Unknown or untrusted sources
- Any skill that requests sensitive access

## Trigger Phrases

The user may say:
- "Audit this skill before I install it"
- "Scan [skill-name] for security issues"
- "Is [skill-name] safe to install?"
- "Check this skill for malware"
- "I want to install [skill] but want to check it first"

## Core Rules

1. **Never execute skill code** - only READ and ANALYZE
2. **Always explain findings** in plain language
3. **Provide clear risk ratings** with justification
4. **Recommend action** based on findings
5. **Respect user's decision** but warn appropriately
6. **Log all audits** for transparency
7. **Clean up temp files** after scanning

## Workflow

### 1) Identify Target

Ask the user (numbered options):

1. Scan a skill from ClawHub (provide name)
2. Scan a local skill directory (provide path)
3. Scan a GitHub repository (provide URL)
4. Scan all installed skills (comprehensive audit)
5. Scan a specific file or archive

If the user provides a URL or name directly, proceed without asking.

### 2) Fetch the Skill

**For ClawHub skill:**
```bash
# Download to temp directory (DO NOT INSTALL)
TEMP_DIR=$(mktemp -d)
clawhub download "$SKILL_NAME" "$TEMP_DIR" 2>/dev/null || {
  # Fallback: manual fetch
  git clone "https://github.com/clawhub/$SKILL_NAME" "$TEMP_DIR" 2>/dev/null
}
```

**For GitHub repository:**
```bash
TEMP_DIR=$(mktemp -d)
git clone "$REPO_URL" "$TEMP_DIR" --depth 1
```

**For local directory:**
```bash
TEMP_DIR="$PROVIDED_PATH"
```

**For all installed skills:**
```bash
TEMP_DIR="$HOME/.openclaw/skills/"
```

### 3) Run Security Checks

Execute each check and collect results:

#### Check A: Malware Detection

**What it detects:**
- Known malware signatures
- Suspicious binary files
- Mach-O executables (macOS malware)
- Encoded payloads (base64, hex, etc.)
- Known malicious domains
- CVE-2026-25253 indicators

```bash
./checks/malware_detection.sh "$TEMP_DIR" > "$RESULTS_DIR/malware.txt"
```

#### Check B: Prompt Injection Analysis

**What it detects:**
- Direct prompt injection ("ignore previous instructions")
- Indirect injection via data sources
- Multi-turn attack patterns
- Jailbreak attempts
- Role manipulation ("you are now...")
- Instruction override attempts
- Hidden instructions in comments/encoding

```bash
./checks/prompt_injection.sh "$TEMP_DIR" > "$RESULTS_DIR/injection.txt"
```

#### Check C: Credential Exposure

**What it detects:**
- Hardcoded API keys
- Passwords in plain text
- OAuth tokens
- Private keys (SSH, PGP, crypto)
- AWS/GCP/Azure credentials
- Database connection strings
- Secret patterns (sk-*, xoxb-*, etc.)

```bash
./checks/credential_exposure.sh "$TEMP_DIR" > "$RESULTS_DIR/credentials.txt"
```

#### Check D: Network Call Analysis

**What it detects:**
- External API calls
- Phone-home behavior
- Data exfiltration endpoints
- Suspicious domains
- Unencrypted connections
- Known malicious IPs
- Unexpected network activity

```bash
./checks/network_calls.sh "$TEMP_DIR" > "$RESULTS_DIR/network.txt"
```

#### Check E: Permission Scope Review

**What it detects:**
- File system access scope
- Shell command execution
- Process spawning
- Access to sensitive directories (~/.ssh, ~/.gnupg, etc.)
- Environment variable access
- Home directory enumeration
- Keychain/credential manager access

```bash
./checks/permissions.sh "$TEMP_DIR" > "$RESULTS_DIR/permissions.txt"
```

#### Check F: Dependency Vulnerabilities

**What it detects:**
- Known CVEs in npm packages
- Malicious npm packages
- Outdated dependencies
- Suspicious package names (typosquatting)
- Packages with post-install scripts
- Binary dependencies

```bash
./checks/dependencies.sh "$TEMP_DIR" > "$RESULTS_DIR/deps.txt"
```

#### Check G: Obfuscation Detection

**What it detects:**
- Base64 encoded content
- Hex encoded content
- Unicode obfuscation
- String concatenation tricks
- Eval() and exec() usage
- Minified/obfuscated JavaScript
- Hidden code in comments

```bash
./checks/obfuscation.sh "$TEMP_DIR" > "$RESULTS_DIR/obfuscation.txt"
```

#### Check H: Social Engineering Patterns

**What it detects:**
- Urgency manipulation
- Fake official language
- Request for credentials
- Social proof manipulation
- Authority claims ("official", "verified")
- Phishing patterns

```bash
./checks/social_engineering.sh "$TEMP_DIR" > "$RESULTS_DIR/social.txt"
```

### 4) Analyze Results

Read each check output and compile findings:

```bash
# Read all results
MALWARE=$(cat "$RESULTS_DIR/malware.txt")
INJECTION=$(cat "$RESULTS_DIR/injection.txt")
CREDENTIALS=$(cat "$RESULTS_DIR/credentials.txt")
NETWORK=$(cat "$RESULTS_DIR/network.txt")
PERMISSIONS=$(cat "$RESULTS_DIR/permissions.txt")
DEPS=$(cat "$RESULTS_DIR/deps.txt")
OBFUSCATION=$(cat "$RESULTS_DIR/obfuscation.txt")
SOCIAL=$(cat "$RESULTS_DIR/social.txt")

# Count findings
CRITICAL=$(grep -c "🚨 CRITICAL" "$RESULTS_DIR"/*.txt 2>/dev/null || echo 0)
HIGH=$(grep -c "⚠️ HIGH" "$RESULTS_DIR"/*.txt 2>/dev/null || echo 0)
MEDIUM=$(grep -c "🔶 MEDIUM" "$RESULTS_DIR"/*.txt 2>/dev/null || echo 0)
LOW=$(grep -c "🔹 LOW" "$RESULTS_DIR"/*.txt 2>/dev/null || echo 0)
```

### 5) Determine Risk Rating

| Criteria | Rating |
|----------|--------|
| Any CRITICAL finding | 🔴 **DANGER** |
| 2+ HIGH findings | 🔴 **DANGER** |
| 1 HIGH finding | 🟠 **WARNING** |
| 2+ MEDIUM findings | 🟠 **WARNING** |
| 1 MEDIUM finding | 🟡 **CAUTION** |
| Only LOW findings | 🟡 **CAUTION** |
| No findings | 🟢 **SAFE** |

### 6) Generate Report

Present findings in clear format:

```markdown
# 🛡️ SKILL AUDIT REPORT

**Skill:** [skill-name]
**Scanned:** [timestamp]
**Files Analyzed:** [count]
**Risk Level:** [RATING]

---

## Summary

[1-3 sentence summary of overall risk]

## Findings

### [Category Name]: [STATUS]

**Severity:** [CRITICAL/HIGH/MEDIUM/LOW]

[Description of finding]

[Evidence if available]

---

## What This Skill Can Access

If installed, this skill would have access to:

- [List of systems/data based on permissions]

## Recommendation

[Clear recommendation based on risk level]

[Next steps for user]
```

### 7) Present Options

After report, offer (numbered):

1. ✅ Install this skill (if SAFE)
2. 📋 Export full report to file
3. 🔍 Deep dive on specific finding
4. 🗑️ Delete downloaded files
5. 📊 Compare to known safe skills
6. 🚫 Do not install (recommended if DANGER/WARNING)

### 8) Execute User Choice

**If user chooses to install:**

For 🟢 SAFE skills:
```bash
clawhub install "$SKILL_NAME"
```

For 🟡 CAUTION:
> "This skill has some concerns. Installing anyway?"

For 🟠 WARNING or 🔴 DANGER:
> "⚠️ This skill has significant security risks. I strongly recommend NOT installing. Proceed anyway? (yes/no)"

**If user chooses export:**
```bash
cp "$RESULTS_DIR/report.md" "~/skill-audit-[skill-name]-$(date +%Y%m%d).md"
echo "Report saved to: ~/skill-audit-[skill-name]-$(date +%Y%m%d).md"
```

**If user chooses delete:**
```bash
rm -rf "$TEMP_DIR"
rm -rf "$RESULTS_DIR"
echo "Temporary files cleaned up."
```

### 9) Cleanup

Always clean up temporary files after audit:

```bash
# Remove temp directory
[ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"

# Keep results for 24 hours in case user wants to review
# Results stored in: ~/.cache/skill-auditor/results/
mkdir -p ~/.cache/skill-auditor/results/
mv "$RESULTS_DIR" ~/.cache/skill-auditor/results/$(date +%s)/

# Optional: clean up old results (>7 days)
find ~/.cache/skill-auditor/results/ -mtime +7 -type d -exec rm -rf {} + 2>/dev/null
```

---

## Risk Rating System

| Rating | Meaning | Action |
|--------|---------|--------|
| 🟢 **SAFE** | No security issues found | Install with confidence |
| 🟡 **CAUTION** | Minor concerns detected | Review findings, proceed carefully |
| 🟠 **WARNING** | Significant security risks | Do not install without understanding risks |
| 🔴 **DANGER** | Malicious or highly dangerous | Do NOT install under any circumstance |

---

## Detailed Check Descriptions

### A. Malware Detection

**Patterns detected:**
- Known malware hashes
- Suspicious binary files (.exe, .dll, .so, .dylib)
- Mach-O executables (macOS)
- ELF binaries (Linux)
- Encoded payloads (base64, hex, rot13)
- Known malicious domains:
  - `openclawcli[.]vercel[.]app`
  - AMOS stealer domains
- CVE-2026-25253 indicators
- ZIP files containing executables

**Severity:** CRITICAL if malware found

### B. Prompt Injection Detection

**Patterns detected:**
```
ignore (all )?(previous|above|prior)
disregard (all )?(previous|above)
forget (all )?(previous|above)
you are now
new instructions
system:
assistant:
override
bypass
jailbreak
DAN (Do Anything Now)
sudo mode
developer mode
```

**Obfuscation variants:**
- Base64 encoded instructions
- Unicode homoglyphs
- Character substitution
- Split across multiple lines
- Hidden in comments

**Severity:** HIGH if injection found

### C. Credential Exposure

**Patterns detected:**
```
api[_-]?key
secret[_-]?key
access[_-]?token
bearer
password
private[_-]?key
aws_access_key
sk-[a-zA-Z0-9]{20,}     # OpenAI
xox[baprs]-[a-zA-Z0-9-]+ # Slack
ghp_[a-zA-Z0-9]{36}     # GitHub
github_pat_             # GitHub fine-grained
AKIA[A-Z0-9]{16}        # AWS
ya29.[a-zA-Z0-9_-]+     # Google
```

**Severity:** HIGH if credentials found

### D. Network Call Analysis

**Patterns detected:**
```
curl|wget|fetch|axios|request\.get|request\.post
http://|https://
api\.
webhook
phone.?home
exfil|exfiltrat
\.(io|xyz|tk|ml|ga|cf)/
```

**Suspicious if:**
- Calls to non-standard domains
- No legitimate API purpose
- Encoded URLs
- POST requests to unknown endpoints

**Severity:** MEDIUM-HIGH depending on context

### E. Permission Scope Review

**Sensitive paths:**
```
~/.ssh/
~/.gnupg/
~/.config/
~/.env
~/.aws/
~/.bash_history
/etc/passwd
/etc/shadow
```

**Dangerous commands:**
```
sudo|su |
rm -rf|rm -r
chmod 777
chown
eval\(|exec\(
subprocess|Popen
```

**Severity:** HIGH if sensitive access without legitimate reason

### F. Dependency Vulnerabilities

**Checks:**
- npm audit on package.json
- Known malicious packages
- Typosquatting detection
- Post-install scripts
- Binary dependencies

**Severity:** MEDIUM-HIGH depending on CVE

### G. Obfuscation Detection

**Patterns:**
```
base64|b64|atob|btoa
hex|0x[0-9a-fA-F]+
eval\(|Function\(
String\.fromCharCode
\\x[0-9a-fA-F]{2}
\\u[0-9a-fA-F]{4}
```

**Severity:** MEDIUM (obfuscation is suspicious but not always malicious)

### H. Social Engineering Patterns

**Patterns:**
```
urgent|immediately|act now
official|verified|authorized
we need your
please provide
your account will be
suspended|locked|terminated
```

**Severity:** LOW-MEDIUM (context dependent)

---

## Known Malicious Skills

As of 2026-02-28, the following skills have been identified as malicious:

| Skill | Threat | Status |
|-------|--------|--------|
| [redacted pending disclosure] | Atomic MacOS Stealer | Removed from ClawHub |

**Detection method:** This auditor checks for known IoCs.

---

## Limitations

- Cannot detect zero-day exploits
- Cannot analyze compiled binaries deeply
- May have false positives (legitimate use of flagged patterns)
- Cannot predict future malicious behavior
- Requires skill to be downloaded (not installed) for analysis

---

## Privacy

- All scans run locally
- No data sent to external servers
- Results stored locally in ~/.cache/skill-auditor/
- User controls all data

---

## Version History

- v1.0.0 (2026-02-28) - Initial release

---

## Credits

Created by Ronald 🔍
Part of the Ronald Audit Services

"If you're not auditing, you're not safe."
