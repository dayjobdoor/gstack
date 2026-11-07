# gstack

[Lauren Tan's pstack](https://github.com/cursor/plugins/tree/main/pstack) for [omp](https://github.com/can1357/oh-my-pi): 55 workflow skills and 2 subagents, plus the small adapter layer omp needs to run them.

pstack is a set of engineering skills (`poteto-mode`, `tdd`, `architect`, `interrogate`, `how`, `why`, and more) that push an agent toward fewer lines, deeper investigation, and verified results. It is written for Cursor. This repository makes it installable on omp without changing the upstream text.

> Unrelated to [garrytan/gstack](https://github.com/garrytan/gstack). The name is just a g after p.

## Install

```sh
omp plugin marketplace add dayjobdoor/gstack
omp plugin install gstack@gstack
```

Then, once, in an omp session:

```
/skill:setup-pstack
```

It detects your models and writes `rules/pstack-models.md` in your omp agent directory (`$PI_CODING_AGENT_DIR`, default `~/.omp/agent`). After that, `poteto-mode` is picked automatically for multi-file changes, design choices, and bugs with unknown causes; call it directly with `/skill:poteto-mode`, or start from `/skill:poteto-help`.

Add the marketplace from the GitHub source rather than a local path, and set `marketplace.autoUpdate` to `auto` if you want updates picked up at startup. The default, `notify`, only writes a debug log.

## What is in the box

| Path | What |
| --- | --- |
| `plugin/skills/*` | Upstream pstack skills, unchanged |
| `plugin/agents/` | Upstream `poteto-agent` and `comment-sicko`, unchanged |
| `plugin/docs/guide/` | Upstream guide; `poteto-help` links into it |
| `plugin/skills/omp-adapter` | Maps pstack's Cursor names to omp: `Task`→`task`, `AskQuestion`→`ask`, todolist→`todo`, `readonly`→`scout`/`reviewer`, paths, models |
| `plugin/rules/pstack.md` | Always-apply rule with the `poteto-mode` routing prompt; tells the model to read `omp-adapter` before following a pstack skill |

## How it differs from upstream

- omp does not run Claude Code SessionStart hooks, so the routing prompt ships as an always-apply rule instead.
- Cursor-only steps (Bugbot, Automations, cloud agents) are skipped with a one-line note.
- `task` has an effort field only when the `task.enableEffort` setting is on. `omp-adapter` maps a model's effort level to it when present, and otherwise passes it as prose or drops it.
- Scripts, paths, and transcripts are mapped in `omp-adapter`: `pstack/skills/...` script paths, `$PI_CODING_AGENT_DIR` (omp profiles), omp session JSONL, and a patched `worktree-audit.sh` invocation. `worktree-audit.sh` itself is unchanged.

## Status

Checked on omp 18.12.1:

- The skills, both agents, `omp-adapter`, and the always-apply rule load, and the rule text appears in the system prompt (via `--plugin-dir`).
- `omp plugin marketplace add dayjobdoor/gstack` and `omp plugin install` succeed from the GitHub source, and the skills appear in `omp skills list`.
- The daily sync workflow runs green on GitHub.

Checked on omp 18.18.0 over ACP with `anthropic/claude-haiku-5-5:auto`: `skill://omp-adapter` and `rule://pstack` resolve, `$PI_CODING_AGENT_DIR/rules` is read while `~/.omp/agent/rules` is ignored under a profile, and the patched `worktree-audit.sh` buckets a worktree used today as `verify-recent-chat` (the stock script says `safe`).

With `--no-extensions`, Haiku echoed back `--append-system-prompt` text, a project always-apply rule, and the pstack rule ("You have pstack."), and a `task` subagent echoed the project rule. So rules reach the prompt and subagents. In the profile tested, other extensions hid all of this from the model, so a profile with prompt-rewriting extensions can drop the routing rule.

Not yet verified: startup auto-update and a full `poteto-mode` run end to end on omp. Reports welcome.

## Keeping up with upstream

`tools/sync.sh` re-vendors upstream and writes `VERSION` as `<upstream version>.<rev>`. Four parts is non-semver, so omp treats any difference as an update (a `-1` suffix would sort below the upstream release and never upgrade). `rev` resets when upstream's version changes and increases when vendored content changes under the same version. Bump it by hand for changes to `omp-adapter` or the rule: edit `VERSION`, `plugin/.claude-plugin/plugin.json`, and `.omp-plugin/marketplace.json`.

`.github/workflows/sync.yml` runs daily and opens a PR when upstream changed. Review those PRs: skill text is instructions the agent will follow. It needs the repository setting "Allow GitHub Actions to create pull requests", and GitHub pauses scheduled workflows after 60 days without repository activity.

## License

MIT. Upstream content is Copyright (c) 2026 Lauren Tan; see [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md) for what is whose.
