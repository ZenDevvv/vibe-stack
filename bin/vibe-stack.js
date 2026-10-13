#!/usr/bin/env node
"use strict";

const { spawnSync } = require("node:child_process");
const { cpSync, existsSync } = require("node:fs");
const { dirname, join } = require("node:path");

const PKG_ROOT = dirname(__dirname);
const TARGET = process.cwd();
const FORCE = process.argv.includes("--force");

const argv = process.argv.slice(2).filter((a) => a !== "--force");

// Scaffolding into a project that was already scaffolded would nest a second copy
// of .template/ and re-run every installer.
if (existsSync(join(TARGET, ".template", "setup.sh")) && !FORCE) {
  console.error(
    "This directory already contains a vibe-stack scaffold.\n" +
      "Run in a fresh directory, delete .template/, or pass --force to reinstall over it.",
  );
  process.exit(1);
}

for (const entry of [
  ".template",
  ".project-truth",
  ".agents",
  ".cursor",
  "AGENTS.md",
  "CLAUDE.md",
  "GEMINI.md",
  "LICENSE",
  "README.md",
]) {
  const src = join(PKG_ROOT, entry);
  if (existsSync(src)) {
    cpSync(src, join(TARGET, entry), { recursive: true });
  }
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

const result = spawnSync(
  bash,
  [join(TARGET, ".template", "setup.sh"), ...argv],
  { stdio: "inherit", cwd: TARGET },
);

if (result.error) {
  console.error(`Failed to start ${bash}: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);