#!/usr/bin/env node
"use strict";

const { spawnSync } = require("node:child_process");
const {
  appendFileSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
} = require("node:fs");
const { dirname, join, relative, sep } = require("node:path");

const TEMPLATE = join(dirname(__dirname), "template");
const TARGET = process.cwd();
const args = process.argv.slice(2);
const FORCE = args.includes("--force");
const NO_SETUP = args.includes("--no-setup");
const DRY_RUN = args.includes("--dry-run");
const setupArgs = args.filter((a) => a !== "--force" && a !== "--no-setup");

if (args.includes("-h") || args.includes("--help")) {
  console.log(
    "Usage: npx @zendevvv/vibe-stack [options]\n\n" +
      "Scaffolds .vibe/ into the current directory, then runs .vibe/setup.sh.\n\n" +
      "  --no-setup   Copy files only; run `bash .vibe/setup.sh` later.\n" +
      "  --force      Refresh the tooling in .vibe/. Your truth, workspace, reports, and\n" +
      "               files outside .vibe/ are never overwritten.\n" +
      "  --dry-run    Show what would be copied and installed, without changing anything.\n\n" +
      "Other options are passed to setup.sh (see `bash .vibe/setup.sh --help`).",
  );
  process.exit(0);
}

if (existsSync(join(TARGET, ".vibe", "setup.sh")) && !FORCE && !DRY_RUN) {
  console.error(
    "This directory already contains a Vibe Stack scaffold (.vibe/).\n" +
      "Pass --force to refresh the tooling; your truth, workspace, and reports are kept.",
  );
  process.exit(1);
}

// Root files that point agents at .vibe/AGENTS.md. Appended to an existing file
// rather than replacing it, so a project's own agent instructions survive.
const SHIMS = new Set(["AGENTS.md", "CLAUDE.md", "GEMINI.md"]);
// Files the project owns once scaffolded. Created when missing, never overwritten.
const USER_OWNED = [".vibe/truth/", ".vibe/workspace/", ".vibe/reports/", ".vibe/governance/recommendations.md"];

function* walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else yield path;
  }
}

const actions = { created: [], appended: [], refreshed: [], kept: [] };

for (const src of walk(TEMPLATE)) {
  let rel = relative(TEMPLATE, src).split(sep).join("/");
  // npm strips .gitignore from published packages, so it ships without the dot.
  if (rel === "gitignore") rel = ".gitignore";
  const dest = join(TARGET, rel);

  let action;
  if (!existsSync(dest)) action = "created";
  else if (SHIMS.has(rel)) action = readFileSync(dest, "utf8").includes(".vibe/AGENTS.md") ? "kept" : "appended";
  // --force refreshes only Vibe Stack's own tooling inside .vibe/, never files elsewhere
  // (such as .claude/commands/) that the project may have customized.
  else if (FORCE && rel.startsWith(".vibe/") && !USER_OWNED.some((p) => rel.startsWith(p))) action = "refreshed";
  else action = "kept";

  actions[action].push(rel);
  if (DRY_RUN || action === "kept") continue;
  mkdirSync(dirname(dest), { recursive: true });
  if (action === "appended") appendFileSync(dest, "\n" + readFileSync(src, "utf8"));
  else copyFileSync(src, dest);
}

const verb = DRY_RUN ? "Would have " : "";
for (const [action, files] of Object.entries(actions)) {
  if (action === "kept") continue;
  if (files.length) console.log(`${verb}${action} ${files.length} file(s): ${files.join(", ")}`);
}
const keptExisting = actions.kept.filter((f) => !SHIMS.has(f));
if (keptExisting.length) console.log(`Kept existing: ${keptExisting.join(", ")}`);

if (NO_SETUP) {
  console.log("Skipped setup. Run `bash .vibe/setup.sh` when ready.");
  process.exit(0);
}

// Git for Windows installs bash.exe outside of the default PATH entry, so probe
// the known install locations before giving up on Windows.
const BASH_CANDIDATES =
  process.platform === "win32"
    ? [
        "bash.exe",
        "C:\\Program Files\\Git\\bin\\bash.exe",
        "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
        `${process.env.LOCALAPPDATA ?? ""}\\Programs\\Git\\bin\\bash.exe`,
      ]
    : ["bash"];

const bash = BASH_CANDIDATES.find((candidate) => {
  if (candidate.includes("\\")) return existsSync(candidate);
  const probe = spawnSync(candidate, ["--version"], { stdio: "ignore" });
  return probe.status === 0;
});

if (!bash) {
  console.error(
    "bash was not found on this system. vibe-stack's setup is a bash script.\n" +
      (process.platform === "win32"
        ? "  Windows: install Git for Windows (https://gitforwindows.org/) and re-run from\n" +
          "  Git Bash, or enable WSL (wsl --install) and re-run inside your distro.\n"
        : "  Install bash (macOS and Linux ship it by default).\n"),
  );
  process.exit(1);
}

// A dry run copies nothing, so run the packaged script rather than the project's copy.
const setupScript = join(DRY_RUN ? TEMPLATE : TARGET, ".vibe", "setup.sh");
const result = spawnSync(bash, [setupScript, ...setupArgs], { stdio: "inherit", cwd: TARGET });

if (result.error) {
  console.error(`Failed to start ${bash}: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);
