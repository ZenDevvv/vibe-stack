#!/usr/bin/env bash
# Vibe Stack setup (Bash / macOS / Linux / WSL / Git Bash).
# Installs Graphify, Ponytail, Addy Osmani's Agent Skills, and the design suite.

set -e

# Pinned tool versions. Git-sourced skills are recorded in skills-lock.json by the skills CLI.
SKILLS_CLI="skills@1.7.2"
IMPECCABLE_CLI="impeccable@4.5.2"
GRAPHIFY_PKG="graphifyy==0.9.89"

usage() {
    cat <<'EOF'
Usage: bash .vibe/setup.sh [options]

  --design-profile <full|frontend|minimal|custom>
                           full (default): Taste + Emil motion/mobile + Impeccable
                           frontend: Taste + Impeccable
                           minimal: Impeccable only
                           custom: choose each skill interactively
  --dry-run                Print what would be installed, then exit.
  --commit-initial-setup   Stage and commit after setup.
  -h, --help               Show this help.
EOF
}

DESIGN_PROFILE=""
DRY_RUN=false
COMMIT_INITIAL_SETUP=false
while (($#)); do
    case "$1" in
        --design-profile)
            [[ -n "${2:-}" ]] || { echo "Missing value for --design-profile" >&2; exit 2; }
            DESIGN_PROFILE="$2"
            shift 2
            ;;
        --dry-run) DRY_RUN=true; shift ;;
        --commit-initial-setup) COMMIT_INITIAL_SETUP=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$DESIGN_PROFILE" && -t 0 && -z "${CI:-}" && "$DRY_RUN" == false ]]; then
    echo "Design profile:"
    echo "  [1] full     - Taste + Emil motion/mobile + Impeccable (recommended)"
    echo "  [2] frontend - Taste + Impeccable"
    echo "  [3] minimal  - Impeccable only"
    echo "  [4] custom   - Choose each skill"
    read -r -p "Choose 1-4, or press Enter for full: " choice
    case "$choice" in
        2) DESIGN_PROFILE="frontend" ;;
        3) DESIGN_PROFILE="minimal" ;;
        4) DESIGN_PROFILE="custom" ;;
    esac
fi
DESIGN_PROFILE="${DESIGN_PROFILE:-full}"
# "motion" was an alias for "full" in earlier releases.
[[ "$DESIGN_PROFILE" == "motion" ]] && DESIGN_PROFILE="full"

INSTALL_IMPECCABLE=true
INSTALL_TASTE=false
INSTALL_EMIL=false
INSTALL_PONYTAIL=true
case "$DESIGN_PROFILE" in
    full) INSTALL_TASTE=true; INSTALL_EMIL=true ;;
    frontend) INSTALL_TASTE=true ;;
    minimal|custom) ;;
    *) echo "Invalid design profile: $DESIGN_PROFILE" >&2; exit 2 ;;
esac
if [[ "$DESIGN_PROFILE" == "custom" && "$DRY_RUN" == false ]]; then
    read -r -p "Install Impeccable quality checks? [Y/n] " answer
    [[ "$answer" =~ ^(n|no)$ ]] && INSTALL_IMPECCABLE=false
    read -r -p "Install Taste Skill visual direction? [y/N] " answer
    [[ "$answer" =~ ^(y|yes)$ ]] && INSTALL_TASTE=true
    read -r -p "Install Emil motion/mobile skills? [y/N] " answer
    [[ "$answer" =~ ^(y|yes)$ ]] && INSTALL_EMIL=true
    read -r -p "Install Ponytail anti-bloat rules? [Y/n] " answer
    [[ "$answer" =~ ^(n|no)$ ]] && INSTALL_PONYTAIL=false
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run: no installation, Git, or commit actions will be performed."
    echo "Design profile: $DESIGN_PROFILE"
    echo "  Impeccable: $INSTALL_IMPECCABLE"
    echo "  Taste Skill: $INSTALL_TASTE"
    echo "  Emil motion/mobile: $INSTALL_EMIL"
    echo "  Ponytail: $INSTALL_PONYTAIL"
    exit 0
fi

# Run from the project root (the parent of .vibe/).
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m   🚀 Setting up Vibe Stack                                \033[0m"
echo -e "\033[1;36m==========================================================\033[0m\n"

# 1. Graphify
echo -e "\033[1;33m1️⃣ Installing Graphify...\033[0m"
# Prefer isolated tool installers: system Pythons that follow PEP 668 (Arch, Debian 12+,
# Homebrew) reject a bare `pip install`.
GRAPHIFY_OK=false
if command -v uv &>/dev/null; then
    uv tool install --quiet --upgrade "$GRAPHIFY_PKG" && GRAPHIFY_OK=true
elif command -v pipx &>/dev/null; then
    pipx install --force "$GRAPHIFY_PKG" >/dev/null && GRAPHIFY_OK=true
else
    PY=$(command -v python3 || command -v python || true)
    if [[ -n "$PY" ]]; then
        "$PY" -m pip install --quiet --user "$GRAPHIFY_PKG" && GRAPHIFY_OK=true
    else
        echo -e "\033[1;31m   ⚠️ No uv, pipx, or Python found. Install uv (https://docs.astral.sh/uv/) or Python 3.10+.\033[0m"
    fi
fi
if [[ "$GRAPHIFY_OK" == true ]] && command -v graphify &>/dev/null; then
    if graphify install; then
        echo "   Graphify installed."
    else
        echo "   Graphify package installed, but skill registration failed." >&2
    fi
elif [[ "$GRAPHIFY_OK" == true ]]; then
    echo "   Graphify installed, but 'graphify' is not on PATH. Add your tool bin directory to PATH and run 'graphify install'." >&2
    GRAPHIFY_OK=false
else
    echo "   Graphify installation failed; continuing without it." >&2
fi

# 2. Git repository and Graphify hook
echo -e "\n\033[1;33m2️⃣ Checking Git Repository...\033[0m"
if [ ! -d ".git" ]; then
    (git init -b main >/dev/null 2>&1 || git init >/dev/null 2>&1)
    echo -e "\033[1;32m   ✅ Initialized Git repository (main).\033[0m"
fi
if [[ "$GRAPHIFY_OK" == true && -d ".git" ]]; then
    if graphify hook install; then
        echo "   Installed Graphify post-commit hook."
    else
        echo "   Graphify hook installation failed; continuing." >&2
    fi
fi

# 3. Engineering & Design Skills
echo -e "\n\033[1;33m3️⃣ Installing Engineering & Design Skills...\033[0m"
AGY_AVAILABLE=false
if command -v agy &>/dev/null; then
    AGY_AVAILABLE=true
fi
if command -v npx &>/dev/null; then
    export CI=true

    if [[ "$AGY_AVAILABLE" == true ]]; then
        echo "   Addy Agent Skills deferred to the Antigravity plugin (avoids duplicate installation)."
    else
        echo "   Installing Addy Osmani's Agent Skills..."
        if npx --yes "$SKILLS_CLI" add addyosmani/agent-skills --all; then
            echo "   Agent Skills installed."
        else
            echo "   Agent Skills installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_TASTE" == true ]]; then
        echo "   Installing Taste Skill (visual direction and personas)..."
        if ! npx --yes "$SKILLS_CLI" add https://github.com/Leonxlnx/taste-skill \
            --skill design-taste-frontend --skill high-end-visual-design --skill minimalist-ui \
            --skill industrial-brutalist-ui --skill brandkit --agent '*' --yes; then
            echo "   Taste Skill installation failed; continuing." >&2
        fi
    fi

    # Antigravity gets Ponytail from its plugin instead, matching the Agent Skills handling.
    if [[ "$INSTALL_PONYTAIL" == true && "$AGY_AVAILABLE" == false ]]; then
        echo "   Installing Ponytail (anti-bloat simplicity ladder)..."
        if npx --yes "$SKILLS_CLI" add https://github.com/dietrichgebert/ponytail \
            --skill ponytail --skill ponytail-review --skill ponytail-audit --agent '*' --yes; then
            echo "   Ponytail installed."
        else
            echo "   Ponytail installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_EMIL" == true ]]; then
        echo "   Installing Emil Kowalski's Motion & Mobile Native Skills..."
        if ! npx --yes "$SKILLS_CLI" add emilkowalski/skills \
            --skill animate --skill mobile-native --skill review-animations --skill apple-design \
            --agent '*' --yes; then
            echo "   Emil Skills installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_IMPECCABLE" == true ]]; then
        echo "   Installing Impeccable (design guidance & quality rules)..."
        if ! npx --yes "$IMPECCABLE_CLI" install --yes --scope=project; then
            echo "   Impeccable installation failed; continuing." >&2
        fi
    fi

    unset CI
    echo "   Skill installation phase complete; review any warnings above."
else
    echo -e "\033[1;31m   ⚠️ npx not found. Please install Node.js 18+.\033[0m"
fi

# 4. Agent Environments
if [[ "$AGY_AVAILABLE" == true ]]; then
    echo -e "\n\033[1;33m4️⃣ Installing Antigravity plugins...\033[0m"
    agy plugin install https://github.com/DietrichGebert/ponytail --silent || echo "   Ponytail plugin installation failed; continuing." >&2
    agy plugin install https://github.com/addyosmani/agent-skills.git --silent || echo "   Agent Skills plugin installation failed; continuing." >&2
fi

# 5. Git status / optional commit
echo -e "\n\033[1;33m5️⃣ Reviewing Git Repository...\033[0m"
if [ -d ".git" ]; then
    if [[ "$COMMIT_INITIAL_SETUP" == true ]]; then
        git add .
        if ! git commit -m "feat: initial project setup with agent skills and tools" --quiet; then
            echo "   Nothing committed; check Git identity or repository state." >&2
        fi
    else
        git status --short || echo "   Could not read Git status." >&2
        echo "   No files were staged or committed. Use --commit-initial-setup to create the initial commit."
    fi
fi

echo -e "\n\033[1;32m==========================================================\033[0m"
echo -e "\033[1;32m   🎉 Vibe Stack Ready!                                   \033[0m"
echo -e "\033[1;32m==========================================================\033[0m"
echo ""
echo -e "\033[1;36m👉 WHAT TO DO NEXT:\033[0m"
echo "   1. Open your AI coding assistant (Claude Code / Cursor / Codex / Gemini / Antigravity)."
echo "   2. Describe what you want to build, e.g. 'I want to build a modern personal portfolio.'"
echo "      Already have code in app/? Say 'adopt' first."
echo ""
echo -e "\033[0;90m💡 Optional shortcuts: /spec (write a spec), /plan (break into steps), /review (quality review)\033[0m"
