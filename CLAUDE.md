# Dev Team

This project uses a five-agent Claude Code dev team, defined in `.claude/agents/`:

| Agent | Model | Role |
|-------|-------|------|
| `senior-dev` | opus | Plans the work and threat model, splits it into two packages, reviews the code |
| `junior-dev-1` | sonnet | Implements work package A |
| `junior-dev-2` | sonnet | Implements work package B (in parallel when files don't overlap) |
| `security-reviewer` | opus | Read-only security gate: audits changes, runs scanners, blocks on Critical/High |
| `tester` | sonnet | Writes and runs functional and security tests, runs the dependency audit |

Run the full pipeline with:

```
/devteam <what you want built or fixed>
/devteam --budget low|normal|high <task>    # trade depth for token usage (default: normal)
```

Budgets change models and the number of review/fix rounds. The security gate always runs.
Check remaining plan usage with `/usage` before big runs.

Or call one agent directly: "Use the security-reviewer agent to audit src/api/."

## Team rules
- The senior dev plans and threat-models before anyone writes code.
- Junior devs only edit the files in their own work package.
- **All code follows `.claude/security/secure-coding.md`.** No exceptions for "quick" changes.
- Every change passes the security gate. Critical/High findings block the change.
- The tester only edits test files and never changes production code to make a test pass.
- Nobody reads, prints or commits secrets (`.env`, keys, credentials).
- Nobody commits or pushes unless the user asks.

## Project settings (fill these in for your project)
<!-- The agents read this section to know how to build, test and scan. -->
- Language / framework:
- Install command:
- Build command:
- Test command:
- Lint / format command:
- Security scan commands (e.g. `semgrep --config auto`, `gitleaks detect --no-git`, `npm audit`):
- Sensitive areas (auth, payments, PII, admin): 
- Code style notes:
