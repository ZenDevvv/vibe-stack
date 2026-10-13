#!/usr/bin/env bash
# Checks that the Vibe Stack project-truth structure is intact. Run from anywhere.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

required=(
  .vibe/AGENTS.md
  .vibe/truth/project-truth.md
  .vibe/truth/project-truth-summary.md
  .vibe/truth/terminology.md
  .vibe/truth/requirements.md
  .vibe/truth/architecture.md
  .vibe/truth/design.md
  .vibe/workspace/context.md
  .vibe/workspace/current-task.md
  .vibe/governance/drift-guard.md
)

for file in "${required[@]}"; do
  [[ -s "$file" ]] || { echo "Missing or empty project-truth file: $file" >&2; exit 1; }
done

for shim in AGENTS.md CLAUDE.md GEMINI.md; do
  grep -q '\.vibe/AGENTS\.md' "$shim" 2>/dev/null || { echo "$shim does not point to .vibe/AGENTS.md" >&2; exit 1; }
done

if grep -rEl --include='*.md' --include='*.sh' --exclude='validate.sh' \
    '(^|[[:space:](`])(PRODUCT\.md|DESIGN\.md|\.project/|\.project-truth/|\.template/)' .vibe; then
  echo 'Found obsolete project-truth path reference.' >&2
  exit 1
fi

grep -qi 'adopt' .vibe/AGENTS.md || { echo 'Missing adopt guidance: .vibe/AGENTS.md' >&2; exit 1; }

echo 'Project-truth structure is valid.'
