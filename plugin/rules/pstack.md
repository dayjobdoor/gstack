---
description: pstack routing mandate
alwaysApply: true
---

You have pstack.

Invoke the `poteto-mode` skill (`skill://poteto-mode`) and follow its instructions when a task meets any of these:

- it touches more than one file, or changes a signature other files call
- it involves a design or architecture choice
- it is a bug whose cause is not yet known, or a performance issue

It routes to the right pstack skill from there. For smaller tasks, such as a contained change to one file with an obvious test, a question, or a one-line edit, work directly and verify on the real artifact.

When the intent is already specific, enter that skill directly: `tdd`, `architect`, `how`, `why`, `arena`, `interrogate`.

pstack skills are written in Cursor's tool language. Before following one that names a Cursor tool, subagent field, model slug, or path, read `skill://omp-adapter` once per session for the omp equivalent.

User instructions (AGENTS.md, direct requests) take precedence.
