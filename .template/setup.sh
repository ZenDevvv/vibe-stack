#!/usr/bin/env bash
# One-Click Vibe Coding Stack Setup Script (Bash / macOS / Linux / WSL)
# Installs & Configures: Ponytail, Graphify, and Addy Osmani's Agent Skills.

set -e

DESIGN_PROFILE="full"
DRY_RUN=false
KEEP_ORIGIN=false
RESET_GIT=false
COMMIT_INITIAL_SETUP=false
while (($#)); do
    case "$1" in
        --design-profile)
            [[ -n "${2:-}" ]] || { echo "Missing value for --design-profile" >&2; exit 2; }
            DESIGN_PROFILE="$2"
            shift 2
            ;;
        --dry-run) DRY_RUN=true; shift ;;
        --keep-origin) KEEP_ORIGIN=true; shift ;;
        --reset-git) RESET_GIT=true; shift ;;
        --commit-initial-setup) COMMIT_INITIAL_SETUP=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

case "$DESIGN_PROFILE" in
    full|motion|frontend|minimal|custom) ;;
    *) echo "Invalid design profile: $DESIGN_PROFILE" >&2; exit 2 ;;
esac

if [[ "$KEEP_ORIGIN" == true && "$RESET_GIT" == true ]]; then
    echo "Choose either --keep-origin or --reset-git, not both." >&2
    exit 2
fi

if [[ -t 0 && -z "${CI:-}" && "$DRY_RUN" == false && "$DESIGN_PROFILE" == "full" ]]; then
    echo "Design profile (default: full - the whole stack):"
    echo "  [1] full     - Taste + Emil motion/mobile + Impeccable (recommended)"
    echo "  [2] motion   - Same as full"
    echo "  [3] frontend - Taste + Impeccable"
    echo "  [4] minimal  - Impeccable only"
    echo "  [5] custom   - Choose each design skill"
    read -r -p "Choose 1-5, or press Enter for full: " choice
    case "$choice" in
        2) DESIGN_PROFILE="motion" ;;
        3) DESIGN_PROFILE="frontend" ;;
        4) DESIGN_PROFILE="minimal" ;;
        5) DESIGN_PROFILE="custom" ;;
    esac
fi

INSTALL_IMPECCABLE=true
INSTALL_TASTE=false
INSTALL_EMIL=false
INSTALL_PONYTAIL=true
case "$DESIGN_PROFILE" in
    full) INSTALL_TASTE=true; INSTALL_EMIL=true ;;
    motion|frontend) INSTALL_TASTE=true ;;
esac
[[ "$DESIGN_PROFILE" == "motion" ]] && INSTALL_EMIL=true
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
# Ensure script executes in the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == ".template" ]]; then
    cd "$SCRIPT_DIR/.."
fi

echo -e "\033[1;36m==========================================================\033[0m"
echo -e "\033[1;36m   🚀 Initializing Vibe Coding Supercharged Template      \033[0m"
echo -e "\033[1;36m      Stack: Ponytail + Graphify + Agent Skills           \033[0m"
echo -e "\033[1;36m==========================================================\033[0m\n"

# npm renames .gitignore to .npmignore on install, so it ships as .template/gitignore.
if [[ ! -f .gitignore && -f .template/gitignore ]]; then
    cp .template/gitignore .gitignore
    echo "   Added .gitignore (Node, Python, and Graphify caches)."
fi

# 1. Check Python & Graphify
echo -e "\033[1;33m1️⃣ Checking Python & Graphify...\033[0m"
# Windows ships Python as `python`; macOS and Linux use `python3`.
PY=$(command -v python3 || command -v python || true)
if [[ -n "$PY" ]]; then
    echo "Found Python: $("$PY" --version)"
    if pip3 install --quiet --upgrade graphifyy || pip install --quiet --upgrade graphifyy; then
        if "$PY" -m graphify install 2>/dev/null || graphify install 2>/dev/null; then
            echo "   Graphify installed."
        else
            echo "   Graphify package installed, but skill registration failed." >&2
        fi
    else
        echo "   Graphify installation failed; continuing without it." >&2
    fi
else
    echo -e "\033[1;31m   ⚠️ python3 not found. Please install Python 3.10+.\033[0m"
fi

# 2. Check Git, optionally detach from template, & commit hook
echo -e "\n\033[1;33m2️⃣ Checking Git Repository...\033[0m"
origin_url=$(git remote get-url origin 2>/dev/null || echo "")

if [[ "$origin_url" == *"vibe-stack"* ]]; then
    echo -e "\033[1;33m   🔄 Detected clone of template repository ($origin_url).\033[0m"
    RESET_TEMPLATE_GIT=false

    if [[ "$KEEP_ORIGIN" == true ]]; then
        echo "   Keeping the existing Git repository by request."
    elif [[ "$RESET_GIT" == true ]]; then
        RESET_TEMPLATE_GIT=true
    elif [[ -t 0 && -z "${CI:-}" ]]; then
        echo "   Choose Git setup:"
        echo "     [1] Start fresh - delete Git history and the template remote (default)"
        echo "     [2] Keep existing - preserve Git history and remotes"
        read -r -p "Choose 1-2, or press Enter to start fresh: " git_choice
        if [[ -z "$git_choice" || "$git_choice" == "1" ]]; then
            RESET_TEMPLATE_GIT=true
        elif [[ "$git_choice" == "2" ]]; then
            echo "   Keeping the existing Git repository."
        else
            echo "   Unrecognized choice; keeping the existing Git repository." >&2
        fi
    else
        echo "   Non-interactive setup keeps the existing Git repository. Use --reset-git to start fresh."
    fi

    if [[ "$RESET_TEMPLATE_GIT" == true ]]; then
        echo -e "\033[1;36m   Disconnecting from template and initializing fresh Git repository for your project...\033[0m"
        rm -rf .git
        (git init -b main >/dev/null 2>&1 || git init >/dev/null 2>&1)
        echo -e "\033[1;32m   ✅ Initialized fresh, detached Git repository (main).\033[0m"
    fi
elif [ ! -d ".git" ]; then
    echo -e "\033[1;36m   Initializing fresh Git repository for your project...\033[0m"
    (git init -b main >/dev/null 2>&1 || git init >/dev/null 2>&1)
    echo -e "\033[1;32m   ✅ Initialized fresh Git repository (main).\033[0m"
fi

if [[ -n "$PY" && -d ".git" ]]; then
    if "$PY" -m graphify hook install 2>/dev/null || graphify hook install 2>/dev/null; then
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
        if npx --yes skills add addyosmani/agent-skills --all; then
            echo "   Agent Skills installed."
        else
            echo "   Agent Skills installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_TASTE" == true ]]; then
        echo "   Installing Taste Skill (visual direction)..."
        if ! npx --yes skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend" --agent '*' --yes; then
            echo "   Taste Skill installation failed; continuing." >&2
        fi
    fi

    # Ponytail ships the 7-rung simplicity ladder. It was previously reachable only
    # through the Antigravity plugin, so every other agent silently lost the pillar.
    # Antigravity gets it from that plugin instead, matching the Agent Skills handling.
    if [[ "$INSTALL_PONYTAIL" == true && "$AGY_AVAILABLE" == false ]]; then
        echo "   Installing Ponytail (anti-bloat simplicity ladder)..."
        if npx --yes skills add https://github.com/dietrichgebert/ponytail --skill "ponytail" --agent '*' --yes; then
            echo "   Ponytail installed."
        else
            echo "   Ponytail installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_EMIL" == true ]]; then
        echo "   Installing Emil Kowalski's Motion & Mobile Native Skills..."
        if ! npx --yes skills@latest add emilkowalski/skills --skill "animate" --skill "mobile-native" --skill "review-animations" --agent '*' --yes; then
            echo "   Emil Skills installation failed; continuing." >&2
        fi
    fi

    if [[ "$INSTALL_IMPECCABLE" == true ]]; then
        echo "   Installing Impeccable (design guidance & quality rules)..."
        if ! npx --yes impeccable install --yes --scope=project; then
            echo "   Impeccable installation failed; continuing." >&2
        fi
    fi

    unset CI
    echo "   Skill installation phase complete; review any warnings above."
else
    echo -e "\033[1;31m   ⚠️ npx not found. Please install Node.js 18+.\033[0m"
fi

# 4. Agent Environments
echo -e "\n\033[1;33m4️⃣ Checking Agent Environments...\033[0m"
if [[ "$AGY_AVAILABLE" == true ]]; then
    echo "   Found Antigravity CLI (agy)! Installing plugins..."
    agy plugin install https://github.com/DietrichGebert/ponytail --silent || echo "   Ponytail plugin installation failed; continuing." >&2
    agy plugin install https://github.com/addyosmani/agent-skills.git --silent || echo "   Agent Skills plugin installation failed; continuing." >&2
fi

# 5. Review Git Repository
echo -e "\n\033[1;33m5️⃣ Reviewing Git Repository...\033[0m"
if [ -d ".git" ]; then
    if [[ "$COMMIT_INITIAL_SETUP" == true ]]; then
        git add .
        if ! git commit -m "feat: initial project setup with agent skills and tools" --quiet; then
            echo "   Nothing committed; check Git identity or repository state." >&2
        fi
        echo "   Git finalization phase complete; review any warnings above."
    else
        echo "   Current Git status:"
        git status --short || echo "   Could not read Git status." >&2
        echo "   No files were staged or committed. Use --commit-initial-setup to create the initial commit."
    fi
fi

echo -e "\n\033[1;32m==========================================================\033[0m"
echo -e "\033[1;32m   🎉 Vibe Coding Stack Ready!                           \033[0m"
echo -e "\033[1;32m==========================================================\033[0m"
echo ""
echo -e "\033[1;36m👉 WHAT TO DO NEXT (No terminal commands needed!):\033[0m"
echo "   1. Open your AI coding assistant (Antigravity / Cursor / Claude)."
echo "   2. In the AI chat, simply describe what you want to build:"
echo -e "\033[1;33m      Example: 'I want to build a modern personal portfolio.'\033[0m"
echo ""
echo "   The AI will automatically handle planning, design, and"
echo "   code quality in the background."
echo ""
echo -e "\033[0;90m💡 Optional shortcuts for advanced users:\033[0m"
echo -e "\033[0;90m   /spec   -> Write a PRD before writing code\033[0m"
echo -e "\033[0;90m   /plan   -> Break tasks into small verifiable steps\033[0m"
echo -e "\033[0;90m   /review -> Senior Staff quality review\033[0m"
echo -e "\033[1;32m==========================================================\033[0m"
