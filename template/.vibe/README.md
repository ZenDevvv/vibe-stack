# .vibe

Everything Vibe Stack adds to this project lives here. The root `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` are one-line pointers to `AGENTS.md` in this folder so each agent loads it automatically.

- `AGENTS.md` — the operating contract every agent follows.
- `truth/` — canonical product, requirement, terminology, architecture, decision, principle, and design documents.
- `workspace/` — compact context, the current task, and task-scoped `spec.md` / `plan.md`.
- `governance/` — drift, testing, and recommendation rules.
- `reports/` — temporary investigation and handoff output. Reports never override canonical truth.
- `setup.sh` — installs the skills and tools (`bash .vibe/setup.sh --help`).
- `validate.sh` — checks that the project-truth structure is intact.

The layering is inspired by WWG (Wiki, Workspace, Governance), but contains only the surfaces a small, model-agnostic project needs. Update canonical truth when accepted behavior, scope, terminology, architecture, design direction, or safety boundaries change. Keep implementation history and temporary notes in reports or decisions instead.

## Adopt an existing application baseline

Place or retain your initial application files in `app/`, then tell your coding agent `adopt` (or `/adopt`). The keyword is a portable agent workflow defined in `AGENTS.md`, not a CLI.

The agent inventories and reads relevant files beneath `app/`, writes a dated evidence report in `reports/`, then updates the applicable canonical truth documents only with confirmed findings. It preserves source files and keeps uncertain product, security, and design conclusions as explicit review items. If `app/` is absent or empty, adoption stops and asks for direction.
