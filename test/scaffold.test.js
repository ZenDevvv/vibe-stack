"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const { existsSync, mkdtempSync, readFileSync, readdirSync, writeFileSync } = require("node:fs");
const { tmpdir } = require("node:os");
const { join } = require("node:path");

const CLI = join(__dirname, "..", "bin", "vibe-stack.js");

function run(cwd, ...args) {
  return spawnSync(process.execPath, [CLI, ...args], { cwd, encoding: "utf8" });
}

const fresh = () => mkdtempSync(join(tmpdir(), "vibe-stack-"));
const read = (dir, file) => readFileSync(join(dir, file), "utf8");

test("scaffolds .vibe/ and root shims into an empty directory", () => {
  const dir = fresh();
  const result = run(dir, "--no-setup");
  assert.equal(result.status, 0, result.stderr);

  assert.deepEqual(readdirSync(dir).sort(), [".claude", ".gemini", ".gitignore", ".vibe", "AGENTS.md", "CLAUDE.md", "GEMINI.md", "app"]);
  assert.match(read(dir, "CLAUDE.md"), /@\.vibe\/AGENTS\.md/);

  const validate = spawnSync("bash", [join(dir, ".vibe", "validate.sh")], { encoding: "utf8" });
  assert.equal(validate.status, 0, validate.stderr);
});

test("preserves existing project files and appends to existing agent files", () => {
  const dir = fresh();
  writeFileSync(join(dir, "README.md"), "my readme\n");
  writeFileSync(join(dir, "CLAUDE.md"), "my rules\n");
  writeFileSync(join(dir, ".gitignore"), "secret/\n");

  assert.equal(run(dir, "--no-setup").status, 0);
  assert.equal(read(dir, "README.md"), "my readme\n");
  assert.equal(read(dir, ".gitignore"), "secret/\n");
  assert.match(read(dir, "CLAUDE.md"), /^my rules\n[\s\S]*@\.vibe\/AGENTS\.md/);
});

test("refuses to re-scaffold without --force", () => {
  const dir = fresh();
  run(dir, "--no-setup");
  const again = run(dir, "--no-setup");
  assert.equal(again.status, 1);
  assert.match(again.stderr, /already contains/);
});

test("--force refreshes .vibe/ tooling but never project truth or files outside .vibe/", () => {
  const dir = fresh();
  run(dir, "--no-setup");
  writeFileSync(join(dir, ".claude", "commands", "review.md"), "my review\n");
  writeFileSync(join(dir, ".vibe", "truth", "project-truth.md"), "accepted truth\n");
  writeFileSync(join(dir, ".vibe", "AGENTS.md"), "stale contract\n");
  const claude = read(dir, "CLAUDE.md");

  assert.equal(run(dir, "--no-setup", "--force").status, 0);
  assert.equal(read(dir, ".vibe/truth/project-truth.md"), "accepted truth\n");
  assert.notEqual(read(dir, ".vibe/AGENTS.md"), "stale contract\n");
  assert.equal(read(dir, "CLAUDE.md"), claude);
  assert.equal(read(dir, ".claude/commands/review.md"), "my review\n");
});

test("ships the same slash commands for Claude Code and Gemini CLI", () => {
  const template = join(__dirname, "..", "template");
  const claude = readdirSync(join(template, ".claude", "commands")).map((f) => f.replace(/\.md$/, ""));
  const gemini = readdirSync(join(template, ".gemini", "commands")).map((f) => f.replace(/\.toml$/, "").replace(/^planning$/, "plan"));
  assert.deepEqual(claude.sort(), gemini.sort());
  for (const c of claude) assert.match(read(template, `.claude/commands/${c}.md`), /\.vibe\//);
});

test("--dry-run changes nothing", () => {
  const dir = fresh();
  const result = run(dir, "--dry-run", "--design-profile", "minimal");
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /Would have created/);
  assert.deepEqual(readdirSync(dir), []);
  assert.equal(existsSync(join(dir, ".vibe")), false);
});
