# Changelog

All notable changes to the Skill Auditor project will be documented in this file.

## [1.1.0] - 2026-02-28

### Fixed
- **False positive reduction**: Tuned detection rules to reduce false positives on legitimate security tools
- `permissions.sh`: Removed generic "credentials"/"secrets" matches that flagged documentation
- `social_engineering.sh`: Made patterns context-aware (only flag when combined with manipulation indicators)
- `prompt_injection.sh`: Fixed overly broad "important.*follow" pattern
- `network_calls.sh`: Only flag URLs in code files, not markdown documentation

### Verified
- All 4 official OpenClaw skills now pass cleanly:
  - healthcheck ✅
  - skill-creator ✅
  - weather ✅
  - tmux ✅
- All malicious test patterns still detected correctly
- Test suite: 5/5 passing

## [1.0.0] - 2026-02-28

### Added
- Initial release
- 8 comprehensive security checks:
  1. Malware Detection
  2. Prompt Injection Analysis
  3. Credential Exposure
  4. Network Call Analysis
  5. Permission Scope Review
  6. Dependency Vulnerabilities
  7. Obfuscation Detection
  8. Social Engineering Patterns
- Risk rating system: SAFE / CAUTION / WARNING / DANGER
- Comprehensive test suite
- Full documentation (README, SKILL.md, deployment guides)
