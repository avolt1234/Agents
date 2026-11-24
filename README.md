# Dev Team boilerplate for Claude Code

A ready-made team of Claude Code subagents: **1 senior dev, 2 junior devs, 1 security reviewer,
1 tester**, plus a `/devteam` command that runs them as a pipeline with a security gate.

```
            /devteam "add password reset"
                        |
             senior-dev (PLAN + threat model)
                 /                \
       junior-dev-1            junior-dev-2      <- in parallel, disjoint files
                 \                /
               senior-dev (CODE REVIEW)    <-- change requests loop (max 2)
                        |
               security-reviewer           <-- BLOCKS on Critical/High (max 2 fix rounds)
                        |
                      tester               <-- functional + security tests, dependency audit
                        |
                  report to you
```

## What's inside

```
.claude/
  agents/
    senior-dev.md         # plans, threat-models, reviews      (model: opus)
    junior-dev-1.md       # implements package A                (model: sonnet)
    junior-dev-2.md       # implements package B                (model: sonnet)
    security-reviewer.md  # read-only security audit + scanners (model: opus)
    tester.md             # functional + security tests         (model: sonnet)
  commands/
    devteam.md            # /devteam orchestration workflow
  security/
    secure-coding.md      # the team's secure coding standard (OWASP-based)
  settings.json           # permission rules: block secrets, git push, risky commands
CLAUDE.md                 # team rules + project settings to fill in
install.ps1               # installer for Windows
install.sh                # installer for macOS / Linux / Git Bash
```

## Security: how the team keeps code safe

| Layer | What it does |
|---|---|
| **Secure coding standard** (`.claude/security/secure-coding.md`) | One OWASP-based rulebook every agent must follow: secrets, injection, XSS, authn/authz, crypto, logging, dependencies, resource limits, safe defaults. |
| **Threat model in every plan** | The senior dev lists entry points, untrusted input, sensitive data, threats and mitigations before any code is written, and sets security acceptance criteria. |
| **Security-aware implementation** | The juniors must implement the mitigations and justify any new dependency (name@version). They may not disable security controls. |
| **Independent security gate** | `security-reviewer` is **read-only** (it can't "fix" things quietly). It traces input from source to sink, runs installed scanners and rates findings. **Critical/High blocks the change.** |
| **Security tests** | The tester adds abuse-case tests (authz/IDOR, injection payloads, malformed input, secrets not leaking) and runs the dependency audit. |
| **Guardrails** (`.claude/settings.json`) | Claude Code itself denies reading `.env`/keys/SSH/AWS creds, `git push`, `git reset --hard`, `sudo`, `curl \| sh` and similar. It **asks you** before package installs, commits, curl/wget and web fetches. |

### Recommended scanners (optional but strongly advised)
The security reviewer and tester use these **if installed**. They never install anything themselves.

| Purpose | Install |
|---|---|
| Static analysis (all languages) | `pip install semgrep` or `brew install semgrep` |
| Secret detection | `gitleaks` (GitHub releases, `brew install gitleaks`, `winget install gitleaks`) |
| Dependency vulnerabilities (all ecosystems) | `osv-scanner` (GitHub releases, `brew install osv-scanner`) |
| Ecosystem-specific | `npm audit` (built in), `pip-audit`, `bandit`, `cargo audit`, `govulncheck` |

### Limits, so you know what this does and doesn't do
- Permission rules cover Claude's built-in tools and match Bash commands by prefix. They are a
  strong guardrail, not a sandbox: a creative shell command could still read a file. For
  sensitive projects, keep real secrets out of the working folder and enable Claude Code's
  sandbox (`/sandbox`).
- AI review finds many issues but is not a substitute for a human security review or
  penetration test of high-risk systems (payments, auth providers, medical or personal data).
- Claude Code also has a built-in `/security-review` command you can run on a branch as an extra check.

## Requirements
- [Claude Code](https://docs.claude.com/en/docs/claude-code) installed and logged in
  (`claude` in a terminal).
- A plan with access to Opus and Sonnet. If you don't have Opus, change `model: opus`
  to `model: sonnet` in `senior-dev.md` and `security-reviewer.md` (or use `model: inherit`).

## Install on another machine

1. Copy this folder over (zip it, or push it to a git repo and `git clone` it).
2. Run the installer and point it at the project you want the team to work on:

   **Windows (PowerShell)**
   ```powershell
   cd DevTeam
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target "C:\path\to\your-project"
   ```

   **macOS / Linux**
   ```bash
   cd DevTeam
   chmod +x install.sh
   ./install.sh /path/to/your-project
   ```

   - `-Global` / `--global` installs for your user, so the team works in **every** project
     (`~/.claude/...`).
   - Existing files are skipped unless you add `-Force` / `--force`. An existing `settings.json`
     is backed up to `settings.json.bak` before it is overwritten.
   - If the project already has a `.claude/settings.json`, merge the `permissions` block by hand
     (or use `-Force`).

   **No installer:** copying the `.claude` folder and `CLAUDE.md` into the project's
   root folder does the same thing.

3. Open the project's `CLAUDE.md` and fill in **Project settings** (build/test/scan commands,
   sensitive areas). The agents rely on this.
4. Start Claude Code in the project folder and check that everything loaded:
   ```
   claude
   ```
   Then ask Claude:
   > Which subagents are available, and which permission deny rules are active?

   It should name `senior-dev`, `junior-dev-1`, `junior-dev-2`, `security-reviewer` and `tester`,
   and `/devteam` should appear when you type `/dev`. If an agent is missing, check that its
   `.md` file is in `.claude/agents/` and starts with the `---` frontmatter block, then restart
   Claude Code. (Newer Claude Code versions have no `/agents` wizard. Agents are plain files.)

## Usage

Full pipeline:
```
/devteam Add a /health endpoint that returns build version and uptime
```

Single agent:
```
Use the security-reviewer agent to audit the whole src/auth folder.
Use the senior-dev agent to review my uncommitted changes.
Use the tester agent to write tests for src/utils/date.ts.
```

## Customising
- **Models:** edit `model:` in each agent file (`opus`, `sonnet`, `haiku` or `inherit`).
- **Tools:** edit `tools:` to restrict what an agent may do.
- **Security standard:** add your company's rules to `.claude/security/secure-coding.md`.
- **Guardrails:** add deny/ask rules in `.claude/settings.json`.
- **Team size:** copy `junior-dev-2.md` to `junior-dev-3.md`, change `name:`, and add
  "Work package C" to `senior-dev.md` and `devteam.md`.
- **Loop limits:** change "Maximum 2" in `.claude/commands/devteam.md`.

## Notes
- Subagents can't call each other. The main Claude session acts as the orchestrator
  and passes each agent's output to the next; `/devteam` gives it the script.
- The juniors run in parallel only when the senior dev gives them disjoint files.
  That avoids edit conflicts in the same working copy.
- No agent commits or pushes. You stay in control of git.
