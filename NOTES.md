# Maintainer notes — chatgpt-share-export

Internal notes for whoever maintains or tunes this skill. Not loaded by the skill
at runtime; safe to ignore during normal use.

## Description optimization (trigger tuning)

The skill's `description` (SKILL.md frontmatter) is what makes Claude decide to
invoke this skill, so it's worth tuning. There's an automated loop that measures
trigger accuracy against a labelled query set and rewrites the description to
maximise it.

### Known limitation: can't run inside the agent session

The optimizer (`run_loop.py`) shells out to `claude -p`. Inside a nested
local-agent session that subprocess **fails with `401 Invalid authentication
credentials`** — it can't inherit the host's OAuth token. So the loop must be run
from a normal, interactive, logged-in terminal, not from within a Claude Code
agent run.

When the loop can't run, fall back to tuning the description by hand against
`../chatgpt-share-export-workspace/trigger_evals.json` (20 labelled queries:
10 should-trigger, 10 tricky should-not-trigger near-misses).

### Run the automated loop yourself

From an authenticated terminal (Python 3.10+ required — system 3.9 is too old for
the scripts' `str | None` type hints):

```bash
# The skill-creator path below is SESSION-SCOPED and may not survive a restart.
# If it's gone, re-invoke the skill-creator skill to get a fresh copy, then point
# $SC at its directory.
SC="/Users/miniaicar/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/32d5285d-ae57-4591-a9f4-73124030703f/cc352669-1de2-4120-9b4c-49c03efd3517/skills/skill-creator"

cd "$SC"
python3.13 -m scripts.run_loop \
  --eval-set ~/.claude/skills/chatgpt-share-export-workspace/trigger_evals.json \
  --skill-path ~/.claude/skills/chatgpt-share-export \
  --model claude-opus-4-8 \
  --max-iterations 5 --verbose
```

It splits the set 60/40 (train/held-out), runs each query 3× to get a stable
trigger rate, iterates up to 5×, and picks the description with the best
*held-out* score (not train — avoids overfitting). It opens an HTML report and
prints JSON containing `best_description`. Copy that into SKILL.md's frontmatter.

Edit `trigger_evals.json` to add/adjust cases before running — better queries
give better descriptions. Keep the should-not-trigger cases genuinely tricky
(other-assistant share links, summarize-only, webpage/docx→PDF, account export).

## Manual tuning done so far

Last hand-tuned against the 20-query set (conceptual pass, loop not run):
expected 10/10 should-trigger, 10/10 should-not-trigger. The current description
explicitly scopes IN (chatgpt.com/share + file intent) and scopes OUT
(claude.ai / gemini shares, summarize-only, generic webpage/.docx/local-file →
PDF, whole-account export, live non-shared session).

## Runtime deps reminder

`npm install` in the skill dir pulls `playwright` + `marked`. Playwright's
**headless shell** is a separate download from the full Chromium — if launch
fails with "Executable doesn't exist … chrome-headless-shell", run
`npx playwright install chromium` once. SKILL.md's bootstrap block handles this.
