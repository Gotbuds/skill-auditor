# 🛡️ Ronald Skill Auditor

**Security scanner for OpenClaw skills.** Detects malware, prompt injection, credential theft, and suspicious behavior before you install.

## Why This Exists

OpenClaw skills can access your files, messages, and system. **Not all skills are safe.**

- **CVE-2026-25253**: Malicious skills distributed via ClawHub
- **Atomic MacOS Stealer**: Malware spread through infected skills
- **Prompt injection**: Hidden instructions that override agent behavior
- **Credential theft**: Skills that steal your API keys and passwords

**Scan BEFORE you install.** 🔍

---

## Installation

### From ClawHub (Recommended)

```bash
clawhub install skill-auditor
```

### From GitHub

```bash
clawhub install https://github.com/ronald-auditor/skill-auditor
```

---

## Usage

After installation, just tell your OpenClaw agent:

> "Audit the skill [skill-name] before I install it"

Or:

> "Scan this skill for security risks: [url]"

Or:

> "Check if [skill-name] is safe to install"

### Example

```
You: Audit the crypto-trader skill before I install it

Agent: Let me scan that for you...

🛡️ AUDIT RESULTS for crypto-trader:

Risk Level: 🟡 CAUTION

Findings:
- ⚠️ Makes external API calls to api.cryptoservice.io
- ⚠️ Requests file system access
- ✅ No credentials found
- ✅ No prompt injection detected

The skill is probably safe but makes network calls.
Your call - want to install it?
```

---

## What It Detects

### 🦠 Malware & Malicious Code
- Known malware signatures
- Suspicious binary files
- Encoded payloads (base64, hex)
- Known malicious domains
- CVE-2026-25253 indicators

### 💉 Prompt Injection
- Direct injection ("ignore previous instructions")
- Indirect injection via data sources
- Role manipulation ("you are now...")
- Jailbreak attempts
- Hidden instructions in comments/encoding

### 🔑 Credential Theft
- Hardcoded API keys
- Passwords in plain text
- OAuth tokens
- Private keys
- AWS/GCP credentials

### 🌐 Data Exfiltration
- External API calls
- Phone-home behavior
- Suspicious network endpoints
- Webhook URLs

### 📁 Excessive Permissions
- Sensitive file access (~/.ssh, ~/.gnupg)
- Shell command execution
- Environment variable access
- Keychain access

### 📦 Vulnerable Dependencies
- Known CVEs in npm packages
- Malicious npm packages
- Post-install scripts
- Binary dependencies

### 🧬 Obfuscation
- Base64 encoded content
- Hex/unicode obfuscation
- eval() and Function() usage
- Zero-width characters

### 🎭 Social Engineering
- Urgency manipulation
- Authority claims
- Credential requests
- Phishing patterns

---

## Risk Ratings

| Rating | Meaning | Action |
|--------|---------|--------|
| 🟢 **SAFE** | No issues found | Install with confidence |
| 🟡 **CAUTION** | Minor concerns | Review findings, proceed carefully |
| 🟠 **WARNING** | Significant risks | Do not install without understanding |
| 🔴 **DANGER** | Malicious or dangerous | **Do NOT install** |

---

## Security Checks

The auditor runs **8 comprehensive security checks**:

1. **Malware Detection** - Known threats and suspicious binaries
2. **Prompt Injection Analysis** - Hidden instructions and jailbreaks
3. **Credential Exposure** - Leaked secrets and API keys
4. **Network Call Analysis** - External connections and data exfiltration
5. **Permission Scope Review** - Excessive access and dangerous commands
6. **Dependency Vulnerabilities** - Vulnerable npm packages
7. **Obfuscation Detection** - Hidden and encoded code
8. **Social Engineering Analysis** - Manipulation and phishing

---

## Privacy

- ✅ All scans run **locally** on your machine
- ✅ **No data** sent to external servers
- ✅ Results stored locally in `~/.cache/skill-auditor/`
- ✅ You control all data

---

## Known Malicious Skills

As of 2026-02-28, the following threats have been identified:

| Threat | Status |
|--------|--------|
| Atomic MacOS Stealer via OpenClaw skills | Active |
| CVE-2026-25253 (OpenClawCLI malware) | Active |

This auditor checks for known indicators of compromise.

---

## Limitations

- Cannot detect zero-day exploits
- Cannot analyze compiled binaries deeply
- May have false positives (legitimate use of flagged patterns)
- Cannot predict future malicious behavior
- Requires skill to be downloaded (not installed) for analysis

---

## Contributing

Found a security issue? Have an improvement?

1. **Security issues**: Email GotbudsAgentstuff@proton.me (or DM on X)
2. **Bug reports**: Open an issue on GitHub
3. **Feature requests**: Open an issue on GitHub
4. **Pull requests**: Welcome!

---

## License

MIT License - Use freely, modify freely, share freely.

---

## Credits

Created by **Ronald** 🔍

*"If you're not auditing, you're not safe."*

---

## Support

- **GitHub Issues**: [github.com/ronald-auditor/skill-auditor/issues](https://github.com/ronald-auditor/skill-auditor/issues)
- **X/Twitter**: [@laxstar131]([https://x.com/laxstar131])
- **OpenClaw Discord**: Join the discussion

---

**Stay safe. Audit before you install.** 🛡️
