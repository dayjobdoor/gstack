---
name: omp-adapter
description: Maps pstack's Cursor names (Task, AskQuestion, readonly, models, paths, transcripts) to omp equivalents. Read once per session before following any pstack skill that names a Cursor tool, field, model slug, or path.
---

# pstack on omp

pstack skills use Cursor names. Map each one with the tables below. If a Cursor field has no row, drop it and say so. Never pass a field the tool schema rejects.

## Tools

| Cursor | omp |
| --- | --- |
| `Task` | `task` (`tasks[]` batch; independent tasks go in one call, which runs them in parallel) |
| `AskQuestion` | `ask`. Without a UI, ask in plain text. |
| Open a todolist | `todo` |
| Run another pstack skill (`/name`, "the **name** skill") | `read` `skill://<name>` and follow it. Tell the user to type `/skill:<name>`. |
| `Grep`, `Glob` | `grep`, `glob`, `find` |
| Wait on subagents | `wait`. Never poll. |

## Subagent fields

| Cursor | omp |
| --- | --- |
| `subagent_type: generalPurpose` | omit `agent` (default `task`) |
| `poteto-agent`, `comment-sicko` | `agent: "poteto-agent"`, `agent: "comment-sicko"` |
| `readonly: true` | `agent: "scout"` for research, or `reviewer` for review. Both cannot edit. |
| `readonly: false` | default `task` agent |
| `environment: "cloud"` | no cloud agents. Run locally; for isolated writers use a git worktree via `bash`. |
| `environment: "local"` | omit |
| `cloud_base_branch: <b>` | tell the worker to check out `<b>` first |
| `run_in_background: true` | omit. `task` results arrive automatically. |
| `resume` | spawn a new task and paste the earlier result into its brief |
| `file_attachments` | list the paths in the brief |

## Models

| Cursor | omp |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]` | `model: "<family>"` fuzzy pattern or `anthropic/claude-<family>-<version>`. Effort is not a `task` field: say it in the brief or omit. Drop `-fast`. |
| Non-Claude slug (`grok-*`, `gpt-*`) | use it if `omp models` lists it, else omit `model` and say so |
| `auto`, `inherit-parent` | omit `model` |
| `~/.cursor/rules/pstack-models.mdc` | `~/.omp/agent/rules/pstack-models.md` (an always-apply rule, already in context). If missing, use the skill's default slug. |
| Role value `<model> <effort>` | `model` = first token; effort as above |

## setup-pstack

Write `~/.omp/agent/rules/pstack-models.md` instead of the `.mdc` path, with frontmatter `alwaysApply: true`, then the comment lines, the `# budget` line, and one line per role. Detect models with `omp models`. Overwrite the whole file.

## Paths

| Cursor | omp |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.omp/skills/`, `~/.omp/agent/skills/` |
| `~/.cursor/plugins/` (search for `poteto-mode/SKILL.md`) | `skill://poteto-mode`, or `~/.omp/plugins/` |
| `.cursor/rules/*.mdc` | `.omp/rules/*.md`, `AGENTS.md` |
| Transcripts `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.omp/agent/sessions/<encoded-cwd>/*.jsonl`. Read only this workspace's folder. |

## Cursor-only features

omp has no Cursor Automations, Bugbot, or cloud agents. When a step needs one, say `Skipped on omp: <step>. <reason>.`, then continue. Leave a placeholder for anything a later step needs from it.
