# Vibe Stack

An opinionated starter for working with AI coding agents on code you plan to keep.

[![npm](https://img.shields.io/npm/v/@zendevvv/vibe-stack?logo=npm)](https://www.npmjs.com/package/@zendevvv/vibe-stack)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

One command adds a `.vibe/` folder that gives your agent a project memory, a spec → plan → build → review loop, and a curated set of skills for simplicity, design, and motion. It works with Claude Code, Cursor, Codex, Gemini CLI, and anything else that reads `AGENTS.md`.

```bash
mkdir my-project && cd my-project
npx @zendevvv/vibe-stack
```

> **Status: early (0.x).** The pieces are established open-source tools, but the combined workflow has not been benchmarked. Performance figures quoted below are from each upstream project, not measurements of Vibe Stack.

---

## Why

Agents are fast but forgetful and eager. Left alone they re-derive context every session, over-build, and drift from decisions you already made. Vibe Stack doesn't add a runtime or a framework; it gives the agent a contract and a few well-chosen skills:

- **A project memory it must respect.** `.vibe/truth/` holds accepted product, requirement, architecture, and design decisions. Agents read it before work and update it at closeout; unknowns stay `TBD` instead of being invented.
- **A small-steps workflow.** Spec before code, a plan of ~100-line tasks, test-first implementation, and a review pass.
- **A bias toward less code.** A simplicity ladder (YAGNI → reuse → stdlib → platform → one-liner) before anything new gets written.
- **A map of the codebase.** A knowledge graph the agent can query for blast radius before cross-module changes.

## What's included

| Piece | Source | What it does |
|---|---|---|
| Project truth | Vibe Stack (inspired by [WWG](https://www.npmjs.com/package/@homedesk/wwg)) | `truth/`, `workspace/`, `governance/`, and `reports/` layers in `.vibe/`, plus an `adopt` workflow for existing code. |
| Engineering lifecycle | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 25 skills: spec-driven development, task breakdown, TDD, debugging, code review, security, performance, shipping. |
| Simplicity | [Ponytail](https://github.com/dietrichgebert/ponytail) | The 7-rung simplicity ladder, plus diff review and repo audit for bloat. Upstream reports ~54% fewer generated lines. |
| Codebase map | [Graphify](https://github.com/Graphify-Labs/graphify) | AST knowledge graph with path and dependency queries, kept fresh by a post-commit hook. Upstream reports up to 71.5x fewer tokens per query. |
| Design quality | [Impeccable](https://github.com/pbakaus/impeccable) | Design guidance commands and deterministic audits for contrast, typography, and spacing. |
| Art direction | [Taste Skill](https://github.com/leonxlnx/taste-skill) | Tunable layout dials and opt-in visual personas (soft, minimalist, brutalist). |
| Motion & mobile | [Emil Kowalski's skills](https://github.com/emilkowalski/skills) | Easing, timing, and mobile-native rules, plus an animation review skill. |

The design pieces only apply to projects with a UI; the contract tells agents to skip them for CLIs, services, and libraries. Use `--design-profile minimal` to install only Impeccable.

## How a task flows

Ask in plain language. The agent follows the lifecycle in `.vibe/AGENTS.md`, and the installed skills trigger from their descriptions:

| You say | The agent |
|---|---|
| "I want to add X. Ask me questions, then write a spec." | Clarifies one question at a time, writes `.vibe/workspace/spec.md`. |
| "Break it into tasks." | Writes `.vibe/workspace/plan.md` with small, ordered, verifiable steps. |
| "Build it." | Implements slice by slice, test first, checking the knowledge graph before cross-module edits. |
| "Review it." | Reviews for correctness, security, performance, maintainability, and simplicity, then trims. |

Durable decisions get promoted from the spec into `.vibe/truth/`; the spec and plan are throwaway working files.

**Slash commands** are included for Claude Code (`.claude/commands/`) and Gemini CLI (`.gemini/commands/`): `/spec`, `/plan` (`/planning` in Gemini), `/build`, `/test`, `/review`, `/code-simplify`, and `/ship`. Each one is a short prompt that runs the matching skill and keeps its output in `.vibe/workspace/`. Antigravity gets Addy Osmani's own commands through the plugin that setup installs. Addy's four reviewer agents aren't installed; see [agent-skills](https://github.com/addyosmani/agent-skills) if you want them.

### Existing code

Put it in `app/`, then tell your agent `adopt`. It inventories the files, writes a dated evidence report to `.vibe/reports/`, and promotes only confirmed facts into `.vibe/truth/`. It doesn't modify source, and anything uncertain stays a review question.

---

## Install

**Requirements:** Node 18+ and bash. On Windows, use Git Bash or WSL; the CLI finds Git Bash automatically. Graphify installs through [`uv`](https://docs.astral.sh/uv/) or `pipx` when available, falling back to `pip --user`.

```bash
npx @zendevvv/vibe-stack [options]
```

| Option | Description |
| --- | --- |
| `--design-profile <full\|frontend\|minimal\|custom>` | `full` (default): Taste + Emil + Impeccable. `frontend`: Taste + Impeccable. `minimal`: Impeccable only. `custom`: choose each. |
| `--dry-run` | Show what would be copied and installed, without changing anything. |
| `--no-setup` | Copy files only; run `bash .vibe/setup.sh` later. |
| `--commit-initial-setup` | Stage and commit after setup. |
| `--force` | Refresh the tooling in `.vibe/` for an existing scaffold. |

It's safe in an existing repository. Files you already have are never overwritten; an existing `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md` gets a pointer appended. Setup initializes Git if needed but never deletes history, and never commits unless asked. `--force` refreshes only the tooling in `.vibe/`. It never touches `.vibe/truth/`, `.vibe/workspace/`, `.vibe/reports/`, or anything outside `.vibe/`.

### What gets added

```
my-project/
├── .vibe/
│   ├── AGENTS.md        # The operating contract
│   ├── truth/           # Accepted product, requirements, architecture, design, decisions
│   ├── workspace/       # Current task, context, spec.md / plan.md
│   ├── governance/      # Drift, testing, and recommendation rules
│   ├── reports/         # Evidence and handoffs; never overrides truth
│   ├── setup.sh         # Installs the tools and skills
│   └── validate.sh      # Checks the truth structure
├── .claude/commands/    # Slash commands for Claude Code
├── .gemini/commands/    # Slash commands for Gemini CLI
├── app/                 # Your application code
├── AGENTS.md            # Pointer to .vibe/AGENTS.md (Codex, Cursor, Copilot, …)
├── CLAUDE.md            # @-import of .vibe/AGENTS.md (Claude Code)
├── GEMINI.md            # @-import of .vibe/AGENTS.md (Gemini CLI, Antigravity)
└── .gitignore           # Only if you don't have one
```

The three root pointers exist because each agent only auto-loads its own filename. Setup also installs skills into each agent's own folders: `.agents/skills/` and `agent/skills/`, with symlinks in `.claude/skills/`. It also adds `skills-lock.json`, which pins the exact skill sources, so commit it. Graphify writes `graphify-out/`.

### Updating and removing

Projects are snapshots. To pick up a new release, run `npx @zendevvv/vibe-stack --force`. To remove Vibe Stack, delete `.vibe/` and the pointer lines, then run `npx skills remove --all` and `graphify uninstall --purge`. The first command removes every project skill, including any you added yourself.

---

## Tradeoffs

Know what you're opting into:

- **Context cost.** `.vibe/AGENTS.md` (about 4k tokens) loads every session, and each installed skill's description takes space in the agent's context. That matters most on small-context models.
- **Process overhead.** Spec → plan → TDD → review is worth it for code you'll maintain, but it's slow for a throwaway prototype.
- **Strong opinions.** The design rules push toward one aesthetic: no Inter, no pure black, decelerating motion. Change `.vibe/AGENTS.md` and `.vibe/truth/design.md` if that's not yours.
- **Overlapping instructions.** Several skill sets plus your agent's built-in behavior sometimes give competing advice. The contract sets a precedence order, but agents don't always follow it.
- **Truth upkeep.** The project memory only helps if it stays current. Review what agents write to `.vibe/truth/`.
- **Third-party code.** Setup runs installers from several projects and adds a post-commit hook. Skills are instructions your agent follows, so review upstream changes before updating.

## Supported agents

- **Claude Code** via `CLAUDE.md`
- **Gemini CLI and Antigravity** via `GEMINI.md`
- **Cursor, Codex, GitHub Copilot, Windsurf, OpenCode, Aider, Cline, and Roo Code** via `AGENTS.md`

The contract is plain Markdown and works with any model. Extra skills and tools are documented in [`docs/`](docs/), including img2threejs for procedural 3D and OmniRoute for model routing.

## Contributing

```bash
npm test             # scaffold tests
npm run lint:setup   # bash syntax check
```

To release, push a `v*` tag matching `package.json` (`npm version minor && git push --follow-tags`). CI publishes to npm with provenance, and refuses to publish on a version mismatch.
