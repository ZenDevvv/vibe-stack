# Drift Guard

Project drift is a mismatch between accepted truth, requirements, code, tests, generated context, or public documentation.

## Required closeout

- Accepted behavior is represented in `.vibe/truth/`.
- Code and tests agree with the relevant requirements.
- `.vibe/workspace/current-task.md` reflects the completed task.
- Terminology changes are synchronized.
- Graphify is refreshed after module or dependency changes.
- Reports do not contradict canonical truth.

## Severity

- **Green:** aligned; continue.
- **Yellow:** documentation or context lag; review and synchronize.
- **Orange:** significant mismatch; plan or reconcile before broad implementation.
- **Red:** critical conflict, unsafe change, regression, or missing required verification; stop.

Reports should explain evidence and recommended action. They must not silently rewrite `project-truth.md`.
