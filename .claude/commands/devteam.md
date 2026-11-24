---
description: Run the dev team (senior-dev -> 2 junior devs -> review -> security gate -> tester) on a task. Optional --budget low|normal|high
argument-hint: [--budget low|normal|high] <describe the feature, bug or change>
---

You are the **orchestrator** of a five-agent dev team. You coordinate; the agents do the work.
Subagents cannot call each other, so you pass each one's output to the next.
All work must meet the standard in `.claude/security/secure-coding.md`.

**Raw input from the user:** $ARGUMENTS

## 0. Parse the input
- If the input contains `--budget low`, `--budget normal` or `--budget high` (also accept
  `--budget=low` etc.), set **BUDGET** to that value and remove the flag from the task text.
- Otherwise BUDGET = `normal`.
- If the budget value is anything else, tell the user the valid values and stop.
- The rest of the input is the **task**. If the task is empty, ask the user what the team
  should build and stop.

Tell the user in one line: `Budget: <BUDGET>` and what that means (models, rounds).

## Budget profiles

Every time you call an agent, pass the **model** from this table as the Agent tool's `model`
parameter. It overrides the agent file's default.

| Setting | low | normal (default) | high |
|---|---|---|---|
| `senior-dev` model | sonnet | opus | opus |
| `junior-dev-1` / `junior-dev-2` model | haiku * | sonnet | opus |
| `security-reviewer` model | sonnet | opus | opus |
| `tester` model | haiku * | sonnet | opus |
| Parallel juniors | no: one junior unless the task clearly needs two | yes | yes |
| Max code-review rounds | 1 | 2 | 3 |
| Max security fix rounds | 1 | 2 | 3 |
| Max test fix rounds | 1 | 2 | 3 |
| Security scanners | secrets + dependency audit only | all available | all available |
| Plan / report detail | brief | standard | detailed |

\* **Security exception (all budgets):** if a work package touches authentication, authorisation,
crypto, secrets handling, payments, personal data, file-system/OS access or input parsing for
untrusted data, use **at least `sonnet`** for the junior doing it and for the tester. The senior
dev marks such packages `SECURITY-SENSITIVE` in the plan.

**Never skip the security gate, whatever the budget.** Budget changes how deep the team goes, not
whether security is checked.

When you call an agent, start the prompt with `Budget: <BUDGET>` so the agent can size its work:
- `low`: keep output short, focus on the essentials, fewer but high-value tests.
- `normal`: standard depth.
- `high`: be thorough: extra edge cases, deeper review, broader test coverage.

If a budget limit stops the work (rounds used up), say so clearly in the final report and
suggest re-running with a higher budget.

## Workflow

### 1. Plan
Call the `senior-dev` agent in **PLAN** mode with the budget, the full task and any context the
user gave. In `low` budget, tell it to prefer a single work package (B = `NONE`) unless the task
clearly has two independent halves. Ask it to mark security-sensitive packages.
Show the user a short summary of the plan (goal, threat model highlights, work packages, test plan).

### 2. Implement
- If package B is `NONE`: call `junior-dev-1` with package A only.
- If package B does **not** depend on A and parallel juniors are allowed: call `junior-dev-1`
  (package A) and `junior-dev-2` (package B) **in parallel, in the same message**.
- Otherwise (B depends on A, or the budget is `low`): call `junior-dev-1` first, then
  `junior-dev-2` with A's report attached.

Give each junior: the budget, the overall goal, the design and **threat model** sections, **their
own package verbatim**, and the list of files the *other* junior owns (so they stay out of them).

### 3. Code review
Call `senior-dev` in **REVIEW** mode with the plan and the junior reports.
- If `CHANGES REQUESTED`: send each change request to the junior it is addressed to
  (in parallel when they touch different files and the budget allows), then review again.
- Stop after the budget's max code-review rounds. Report any open items to the user and continue.

### 4. Security gate (always runs)
Call `security-reviewer` with: the budget, the task, the threat model, the list of changed files
(from the junior reports) and the senior-dev's "Security notes".
- If `BLOCKED` (any Critical/High): send each finding to its suggested owner (junior or senior-dev),
  then call `security-reviewer` again on the fixed files.
- Stop after the budget's max security rounds. If Critical/High findings remain after that,
  **stop**: do not continue to testing, and report the result to the user as `BLOCKED` with
  the findings.
- Medium/Low findings: fix them if the fix is small, otherwise list them as follow-ups.

### 5. Test
Call `tester` with the budget, the plan's test plan (including the security cases), the acceptance
criteria, the list of changed files, the review notes and the security reviewer's "Security tests
the tester should add".
- If `FAIL`: route each defect to its suggested owner, then re-run `tester`.
- Stop after the budget's max test fix rounds and report to the user.
- If a fix in this step touched security-relevant code, run `security-reviewer` once more on it.

### 6. Report to the user
```
## Dev team result: DONE | DONE WITH OPEN ISSUES | BLOCKED
- Budget: low | normal | high  (rounds used: review x/y, security x/y, test x/y)
- Summary of the change
- Files changed (by whom)
- Code review verdict
- Security review verdict (+ scanners run, open Medium/Low findings)
- Test result (commands + pass/fail counts, security tests, dependency audit)
- New dependencies added (name@version)
- Open issues / follow-ups (and whether a higher budget would help)
```

## Rules
- Do not write production code yourself; delegate. You may read files to give agents context.
- Never skip the security gate, even for "small" changes or a `low` budget.
- Never read or pass on the contents of `.env` files, keys or credentials.
- Do not commit or push unless the user asks.
- Keep the user informed with one line between phases ("Plan ready. Juniors implementing...").
