---
name: omp-adapter
description: Maps pstack's Cursor names (Task, AskQuestion, readonly, models, paths, scripts, transcripts) to omp equivalents. Read once per session before following any pstack skill that names a Cursor tool, field, model slug, script, or path.
---

# pstack on omp

pstack skills use Cursor names. Map each one with the tables below. If a Cursor field has no row, drop it and say so. Never pass a field the tool schema rejects.

`$AGENT_DIR` is `$PI_CODING_AGENT_DIR` when set (omp profiles set it), else `~/.omp/agent`. With a profile, `~/.omp/agent/rules` is not read.

## Tools

| Cursor | omp |
| --- | --- |
| `Task` | `task`. Independent tasks go in one `tasks[]` call and run in parallel. |
| `AskQuestion` | `ask`: 2-5 options per question. Without a UI, ask in plain text. |
| Open a todolist | `todo` |
| Run another pstack skill (`/name`, "the **name** skill") | `read` `skill://<name>` and follow it. Tell the user to type `/skill:<name>`. |
| `Grep`, `Glob` | `grep`, `glob`, `find` |
| Wait on subagents | `wait`. Never poll. |

## Task fields

| Cursor | omp |
| --- | --- |
| `prompt` | `tasks[].task`. Material shared by every task goes in `context`. |
| `description` | `tasks[].name` (CamelCase, 32 chars max) |
| (none) | `tasks[].solutionSpace` is required: how open-ended the child's problem is. |
| `subagent_type: generalPurpose` | omit `agent` (default `task`) |
| `poteto-agent`, `comment-sicko` | `agent: "poteto-agent"`, `agent: "comment-sicko"`, set per task item |
| `readonly: true` | `agent: "scout"` for research, or `reviewer` for review. Both cannot edit. |
| `readonly: false` | default `task` agent |
| `environment: "cloud"` | no cloud agents. Run locally; for isolated writers use a git worktree via `bash`. |
| `environment: "local"` | omit |
| `cloud_base_branch: <b>` | tell the worker to check out `<b>` first |
| `run_in_background: true` | omit. `task` results arrive automatically. |
| `resume`, steer, or queue a follow-up on a running agent | `write` to `agent://<id>`. A stop or hold order: `write` to `proc://<id>/kill`. |
| `resume` of an agent that already returned | spawn a new task and paste the earlier report into its brief |
| `file_attachments` | list the paths in the brief |

Every brief to a pstack subagent starts with: read `skill://omp-adapter` first. The subagent may not carry the always-apply rule.

## Models

| Cursor | omp |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]` | `model: "<family>"` fuzzy pattern or `anthropic/claude-<family>-<version>`. Drop `-fast`. |
| Effort | pass it only if the `task` schema has an `effort` field (setting `task.enableEffort`): `low`→`lo`, `medium`→`med`, `high`/`xhigh`/`max`→`hi`. Otherwise say it in the brief or omit. |
| Non-Claude slug (`grok-*`, `gpt-*`) | use it if `omp models` lists it, else omit `model` and say so |
| `auto`, `inherit-parent` | omit `model` |
| `~/.cursor/rules/pstack-models.mdc` | `$AGENT_DIR/rules/pstack-models.md` (an always-apply rule, already in context). If missing, use the skill's default slug. |
| Role value `<model> <effort>` | `model` = first token; effort as above |

## setup-pstack

Write `$AGENT_DIR/rules/pstack-models.md` instead of the `.mdc` path, with frontmatter `alwaysApply: true`, then the comment lines, the `# budget` line, and one line per role. Detect models with `omp models`. Overwrite the whole file.

## Paths

| Cursor | omp |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.omp/skills/`, `$AGENT_DIR/skills/` |
| `~/.cursor/plugins/` (search for `poteto-mode/SKILL.md`) | `read skill://poteto-mode`. Its first line, `[Skill file: <path>]`, is the absolute path to give a subagent. |
| `.cursor/rules/*.mdc` | `.omp/rules/*.md`, `AGENTS.md` |
| `pstack/skills/<name>/scripts/<file>` | `read skill://<name>/scripts/<file>` and run the absolute path from its `[Skill file: ...]` header. The relative `pstack/...` path does not exist. |

## Transcripts

| Cursor | omp |
| --- | --- |
| `~/.cursor/projects/<slug>/agent-transcripts/` (the system prompt names it) | `$AGENT_DIR/sessions/<encoded-cwd>/`. Do not compute `<encoded-cwd>`. Use `dirname "$PI_SESSION_FILE"`. Read only this workspace's folder. |
| The active transcript | `$PI_SESSION_FILE` |
| Flat, nested, and `subagents/` layouts | `<ts>_<id>.jsonl` plus a sibling folder `<ts>_<id>/` holding subagent `*.jsonl`, bash logs, and artifacts. Skip `__advisor.*.jsonl`: advisor side notes, not conversation. |
| First JSONL line holds the opening prompt | Line 1 is a `title` entry. A turn is `{"type":"message","message":{"role":"user"\|"assistant"\|"toolResult","content":[{"type":"text","text":...}]}}`. The first user turn is the first `message` entry with `role: "user"`. |

## worktree-audit.sh

The script reads `~/.cursor/projects`, which omp does not write. `LAST_CHAT` is then `-`, `verify-recent-chat` never fires, and a worktree used in a chat today is bucketed `safe`. Run a patched copy instead:

```bash
S=$(mktemp); sed 's#^transcripts=.*#transcripts="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}/sessions"#' <abs-path-to>/worktree-audit.sh > "$S"; bash "$S" -b <base>
```

It matches the exact worktree path inside session files and prints only a date. Git lists canonical paths, so a session started through a symlink (`/tmp` vs `/private/tmp`) is missed. Check such worktrees by hand before deleting.

## Cursor-only features

omp has no Cursor Automations, Bugbot, or cloud agents. `make-bot-ui` and `poteto-mode/references/bugbot-triage.md` need them entirely. When a step needs one, say `Skipped on omp: <step>. <reason>.`, then continue. Leave a placeholder for anything a later step needs from it.
