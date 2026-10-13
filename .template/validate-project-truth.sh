#!/usr/bin/env bash
set -euo pipefail

required=(
  .project-truth/truth/project-truth.md
  .project-truth/truth/project-truth-summary.md
  .project-truth/truth/terminology.md
  .project-truth/truth/requirements.md
  .project-truth/truth/architecture.md
  .project-truth/truth/design.md
  .project-truth/workspace/context.md
  .project-truth/workspace/current-task.md
  .project-truth/governance/drift-guard.md
)

for file in "${required[@]}"; do
  [[ -s "$file" ]] || { echo "Missing or empty project-truth file: $file" >&2; exit 1; }
done

if grep -rEl --include='*.md' --include='*.mdc' --include='*.sh' \
    --exclude='validate-project-truth.sh' \
    '(^|[[:space:](`])(PRODUCT\.md|DESIGN\.md|\.project/)' \
    AGENTS.md CLAUDE.md GEMINI.md .agents/rules .cursor/rules .template README.md; then
  echo 'Found obsolete project-truth authority or path reference.' >&2
  exit 1
fi

adopt_guidance_files=(
  AGENTS.md
  CLAUDE.md
  GEMINI.md
  .agents/rules/vibe-stack.md
  .cursor/rules/graphify.mdc
)

for file in "${adopt_guidance_files[@]}"; do
  grep -qi 'adopt' "$file" || { echo "Missing adopt guidance: $file" >&2; exit 1; }
done

echo 'Project-truth structure is valid.'
