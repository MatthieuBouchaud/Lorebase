#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/lorebase-test.XXXXXX")"
tmp_root="$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).resolve())' "$tmp_root")"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

log() {
  printf '\n[test] %s\n' "$*"
}

fail() {
  printf '\n[test] FAIL: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_command bash
require_command git
require_command python3
require_command node

download_root="$tmp_root/download/lorebase"

log "Copying repo to a fresh download sandbox"
python3 - "$repo_root" "$download_root" <<'PY'
import pathlib
import shutil
import sys

source = pathlib.Path(sys.argv[1]).resolve()
target = pathlib.Path(sys.argv[2]).resolve()
ignore_dirs = {".git", "generated"}
ignore_files = {".DS_Store"}

target.mkdir(parents=True, exist_ok=True)

for child in source.iterdir():
    if child.name in ignore_dirs or child.name in ignore_files:
        continue
    dest = target / child.name
    if child.is_dir():
        shutil.copytree(
            child,
            dest,
            ignore=shutil.ignore_patterns(".git", "generated", ".DS_Store"),
        )
    else:
        shutil.copy2(child, dest)
PY

cd "$download_root"

log "Checking script syntax and executable bits"
for script in scripts/*.sh; do
  [[ -x "$script" ]] || fail "$script is not executable"
  bash -n "$script"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/*.sh
else
  log "shellcheck not installed; skipping optional lint"
fi

log "Validating JSON config examples"
for json_file in config/*.json; do
  python3 -m json.tool "$json_file" >/dev/null
done

log "Checking for local paths and secret-shaped values in shareable files"
python3 - <<'PY'
import pathlib
import re

root = pathlib.Path(".").resolve()
skip_dirs = {".git", "generated", "node_modules", ".venv", "__pycache__"}
skip_files = {".DS_Store"}
secret_prefixes = [
    "s" + "k-",
    "gh" + "p_",
    "github" + "_pat_",
    "xox" + "b-",
    "xox" + "p-",
]
secret_assignment = re.compile(
    r'(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*["\']?([A-Za-z0-9_./+=-]{16,})'
)
absolute_path = re.compile(r"(/Users|/home)/[A-Za-z0-9._-]+")
findings = []

for path in root.rglob("*"):
    rel = path.relative_to(root)
    if any(part in skip_dirs for part in rel.parts) or path.name in skip_files:
        continue
    if path.is_dir():
        continue
    try:
        text = path.read_text(errors="ignore")
    except Exception:
        continue
    for line_number, line in enumerate(text.splitlines(), 1):
        if absolute_path.search(line):
            findings.append(f"{rel}:{line_number}: absolute local path")
        if any(prefix in line for prefix in secret_prefixes):
            findings.append(f"{rel}:{line_number}: secret-like prefix")
        match = secret_assignment.search(line)
        if match and not line.strip().endswith("="):
            findings.append(f"{rel}:{line_number}: secret-like assignment")

if findings:
    print("\n".join(findings))
    raise SystemExit(1)
PY

log "Bootstrapping into an isolated HOME"
export HOME="$tmp_root/home"
mkdir -p "$HOME"

brain_repo="$tmp_root/Brain"
gbrain_repo="$tmp_root/gbrain"
bootstrap_log="$tmp_root/bootstrap.log"
mkdir -p "$gbrain_repo/.git"

./scripts/bootstrap.sh \
  --brain "$brain_repo" \
  --gbrain "$gbrain_repo" \
  --no-gbrain-clone \
  --timezone Europe/Brussels \
  --operator "Smoke User" \
  --model gpt-smoke | tee "$bootstrap_log"

if ! command -v bun >/dev/null 2>&1; then
  grep -q "https://bun.sh/install" "$bootstrap_log" || fail "Bootstrap did not tell a user without Bun how to install it"
fi

log "Verifying bootstrapped Brain repo"
for required in \
  "$brain_repo/AGENTS.md" \
  "$brain_repo/RESOLVER.md" \
  "$brain_repo/schema.md" \
  "$brain_repo/people/README.md" \
  "$brain_repo/companies/README.md" \
  "$brain_repo/projects/README.md" \
  "$brain_repo/daily/calendar/README.md"
do
  [[ -f "$required" ]] || fail "Missing bootstrapped file: $required"
done

[[ "$(git -C "$brain_repo" branch --show-current)" == "main" ]] || fail "Brain repo did not initialize on main"

log "Verifying idempotent bootstrap does not overwrite user files"
custom_file="$brain_repo/inbox/custom.md"
custom_recipe="$gbrain_repo/recipes/email-to-brain.md"
[[ -f "$custom_recipe" ]] || fail "Initial bootstrap did not copy recipes"
printf 'user-owned\n' > "$custom_file"
printf 'user-owned recipe\n' > "$custom_recipe"
./scripts/bootstrap.sh \
  --brain "$brain_repo" \
  --gbrain "$gbrain_repo" \
  --no-gbrain-clone \
  --timezone Europe/Brussels \
  --operator "Smoke User" \
  --model gpt-smoke >/dev/null
[[ "$(cat "$custom_file")" == "user-owned" ]] || fail "Bootstrap overwrote an existing user file"
[[ "$(cat "$custom_recipe")" == "user-owned recipe" ]] || fail "Bootstrap overwrote an existing recipe"
cp recipes/email-to-brain.md "$custom_recipe"

log "Verifying installed Codex skill"
skill_path="$HOME/.codex/skills/source-to-brain-automation/SKILL.md"
[[ -f "$skill_path" ]] || fail "Codex skill was not installed"
grep -q "$brain_repo" "$skill_path" || fail "Codex skill does not point at the bootstrapped Brain repo"
grep -q "$gbrain_repo" "$skill_path" || fail "Codex skill does not point at the source repo"
if grep -q '{{' "$skill_path"; then
  fail "Codex skill still contains template placeholders"
fi

log "Verifying rendered paused automation TOML"
for id in email-to-brain calendar-to-brain slack-to-brain notion-meetings-to-brain telegram-to-brain; do
  toml="generated/codex-automations/$id.toml"
  [[ -f "$toml" ]] || fail "Missing rendered automation: $toml"
  grep -q 'status = "PAUSED"' "$toml" || fail "$toml is not paused by default"
  grep -q "$brain_repo" "$toml" || fail "$toml does not contain Brain path"
  grep -q "$gbrain_repo" "$toml" || fail "$toml does not contain source repo path"
  grep -q "gpt-smoke" "$toml" || fail "$toml does not contain selected model"
  if grep -q '{{' "$toml"; then
    fail "$toml still contains template placeholders"
  fi
done

log "Verifying copied source config examples"
for config_path in \
  "$gbrain_repo/email-sync/config.example.json" \
  "$gbrain_repo/calendar-sync/config.example.json" \
  "$gbrain_repo/slack-sync/config.example.json" \
  "$gbrain_repo/notion-meetings-sync/config.example.json" \
  "$gbrain_repo/telegram-sync/config.example.json"
do
  [[ -f "$config_path" ]] || fail "Missing copied config: $config_path"
  python3 -m json.tool "$config_path" >/dev/null
done

log "Verifying copied source recipes"
for recipe_name in email-to-brain calendar-to-brain slack-to-brain notion-meetings-to-brain telegram-to-brain; do
  recipe_path="$gbrain_repo/recipes/$recipe_name.md"
  [[ -f "$recipe_path" ]] || fail "Missing copied recipe: $recipe_path"
  grep -q "source-state repo" "$recipe_path" || fail "$recipe_path does not describe source-state behavior"
  if grep -q '{{' "$recipe_path"; then
    fail "$recipe_path still contains template placeholders"
  fi
done

python3 - "$gbrain_repo" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for rel in [
    "email-sync/config.example.json",
    "calendar-sync/config.example.json",
    "slack-sync/config.example.json",
    "notion-meetings-sync/config.example.json",
    "telegram-sync/config.example.json",
]:
    data = json.loads((root / rel).read_text())
    if data.get("timezone") != "Europe/Brussels":
        raise SystemExit(f"{rel} did not receive timezone override")
for rel in [
    "slack-sync/config.example.json",
    "telegram-sync/config.example.json",
]:
    data = json.loads((root / rel).read_text())
    if data.get("operator_display_name") != "Smoke User":
        raise SystemExit(f"{rel} did not receive operator override")
PY

log "Verifying default timezone and operator behavior"
default_home="$tmp_root/default-home"
default_brain="$tmp_root/default-brain"
default_gbrain="$tmp_root/default-gbrain"
mkdir -p "$default_home" "$default_gbrain/.git"
HOME="$default_home" ./scripts/bootstrap.sh \
  --brain "$default_brain" \
  --gbrain "$default_gbrain" \
  --no-gbrain-clone \
  --no-install-codex-skill >/dev/null

[[ -f "$default_gbrain/recipes/calendar-to-brain.md" ]] || fail "Default bootstrap did not copy recipes"

python3 - "$default_gbrain" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for rel in [
    "email-sync/config.example.json",
    "calendar-sync/config.example.json",
    "slack-sync/config.example.json",
    "notion-meetings-sync/config.example.json",
    "telegram-sync/config.example.json",
]:
    data = json.loads((root / rel).read_text())
    if not data.get("timezone"):
        raise SystemExit(f"{rel} did not receive a default timezone")
for rel in [
    "slack-sync/config.example.json",
    "telegram-sync/config.example.json",
]:
    data = json.loads((root / rel).read_text())
    if data.get("operator_display_name") != "You":
        raise SystemExit(f"{rel} did not receive neutral operator default")
PY

log "Verifying source-to-brain helper write sets"
for source_id in email-to-brain calendar-to-brain slack-to-brain notion-meetings-to-brain telegram-to-brain; do
  ./scripts/source-to-brain-automation.sh write-set "$source_id" >/dev/null
done

log "Verifying one-command installer with stubbed Bun and GBrain"
install_home="$tmp_root/install-home"
install_brain="$tmp_root/install-brain"
install_gbrain="$tmp_root/install-gbrain"
install_bin="$tmp_root/install-bin"
mkdir -p "$install_home" "$install_gbrain/.git" "$install_bin"

cat > "$install_bin/bun" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$BUN_STUB_LOG"
exit 0
EOF
cat > "$install_bin/gbrain" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$INSTALL_GBRAIN_STUB_LOG"
exit 0
EOF
chmod +x "$install_bin/bun" "$install_bin/gbrain"

BUN_STUB_LOG="$tmp_root/bun-install-stub.log" \
INSTALL_GBRAIN_STUB_LOG="$tmp_root/gbrain-install-stub.log" \
HOME="$install_home" \
PATH="$install_bin:$PATH" \
OPENAI_API_KEY="test-openai-key" \
./scripts/install.sh \
  --brain "$install_brain" \
  --gbrain "$install_gbrain" \
  --no-gbrain-clone \
  --timezone Europe/Brussels \
  --operator "Smoke User" \
  --model gpt-smoke > "$tmp_root/install.log"

[[ -f "$install_brain/AGENTS.md" ]] || fail "Installer did not create Brain repo"
[[ -f "$install_home/.codex/skills/source-to-brain-automation/SKILL.md" ]] || fail "Installer did not install Codex skill"
[[ -f "$install_home/.codex/automations/email-to-brain/automation.toml" ]] || fail "Installer did not install paused automations"
[[ -f "$install_gbrain/recipes/email-to-brain.md" ]] || fail "Installer did not copy source recipes"
grep -q 'status = "PAUSED"' "$install_home/.codex/automations/email-to-brain/automation.toml" || fail "Installed automation is not paused"
grep -qx "install" "$tmp_root/bun-install-stub.log" || fail "Installer did not run bun install"
grep -qx "link" "$tmp_root/bun-install-stub.log" || fail "Installer did not run bun link"
grep -qx "init" "$tmp_root/gbrain-install-stub.log" || fail "Installer did not run gbrain init"
grep -q "doctor --json" "$tmp_root/gbrain-install-stub.log" || fail "Installer did not run gbrain doctor"
grep -q "import $install_brain --no-embed" "$tmp_root/gbrain-install-stub.log" || fail "Installer did not import Brain"
grep -q "embed --stale" "$tmp_root/gbrain-install-stub.log" || fail "Installer did not run initial embeddings when OPENAI_API_KEY was set"

log "Verifying manifest publish path with a stub gbrain"
fake_bin="$tmp_root/bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/gbrain" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GBRAIN_STUB_LOG"
if [[ "${GBRAIN_STUB_FAIL_EMBED:-0}" == "1" && "${1:-}" == "embed" ]]; then
  exit 42
fi
exit 0
EOF
chmod +x "$fake_bin/gbrain"
export PATH="$fake_bin:$PATH"
export GBRAIN_STUB_LOG="$tmp_root/gbrain-stub.log"
: > "$GBRAIN_STUB_LOG"

publish_brain="$tmp_root/publish-brain"
stage_dir="$tmp_root/stage/source/run-1"
mkdir -p "$publish_brain/people" "$stage_dir/people"
cat > "$stage_dir/people/jane-doe.md" <<'EOF'
---
type: person
title: Jane Doe
---

Smoke-test page.
EOF
cat > "$stage_dir/manifest.json" <<'EOF'
{
  "operations": [
    {
      "type": "write",
      "target": "people/jane-doe.md",
      "source": "people/jane-doe.md"
    }
  ]
}
EOF

./scripts/source-to-brain-automation.sh publish-manifest "$publish_brain" "$stage_dir/manifest.json" >/dev/null
[[ -f "$publish_brain/people/jane-doe.md" ]] || fail "publish-manifest did not write the target brain file"
grep -q "import $publish_brain/people/jane-doe.md --no-embed" "$GBRAIN_STUB_LOG" || fail "publish-manifest did not import written page"
grep -q "embed --stale" "$GBRAIN_STUB_LOG" || fail "publish-manifest did not embed stale pages"

log "Verifying manifest no-op skips gbrain"
: > "$GBRAIN_STUB_LOG"
./scripts/source-to-brain-automation.sh publish-manifest "$publish_brain" "$stage_dir/manifest.json" >/dev/null
[[ ! -s "$GBRAIN_STUB_LOG" ]] || fail "No-op publish unexpectedly called gbrain"

log "Verifying delete manifest falls back to sync"
cat > "$stage_dir/delete-manifest.json" <<'EOF'
{
  "operations": [
    {
      "type": "delete",
      "target": "people/jane-doe.md"
    }
  ]
}
EOF
: > "$GBRAIN_STUB_LOG"
./scripts/source-to-brain-automation.sh publish-manifest "$publish_brain" "$stage_dir/delete-manifest.json" >/dev/null
[[ ! -f "$publish_brain/people/jane-doe.md" ]] || fail "delete manifest did not remove target"
grep -q "sync --repo $publish_brain --no-pull --no-embed" "$GBRAIN_STUB_LOG" || fail "delete manifest did not call sync"
grep -q "embed --stale" "$GBRAIN_STUB_LOG" || fail "delete manifest did not embed stale pages after sync"

log "Verifying embedding failure is non-blocking by default"
mkdir -p "$publish_brain/people"
printf 'embed retry page\n' > "$publish_brain/people/embed-retry.md"
: > "$GBRAIN_STUB_LOG"
GBRAIN_STUB_FAIL_EMBED=1 ./scripts/source-to-brain-automation.sh import-path "$publish_brain/people/embed-retry.md" >/dev/null 2>"$tmp_root/embed-fail.err"
grep -q "import $publish_brain/people/embed-retry.md --no-embed" "$GBRAIN_STUB_LOG" || fail "import-path did not import before embedding"
grep -q "embed --stale" "$GBRAIN_STUB_LOG" || fail "import-path did not attempt stale embedding"
grep -q "embedding failed; text import/sync already completed" "$tmp_root/embed-fail.err" || fail "embedding failure did not explain non-blocking behavior"

if GBRAIN_STUB_FAIL_EMBED=1 SOURCE_TO_BRAIN_REQUIRE_EMBEDDINGS=1 ./scripts/source-to-brain-automation.sh import-path "$publish_brain/people/embed-retry.md" >/dev/null 2>&1; then
  fail "Strict embedding mode did not fail when embedding failed"
fi

log "Verifying embedding can be disabled"
: > "$GBRAIN_STUB_LOG"
SOURCE_TO_BRAIN_EMBED_MODE=off ./scripts/source-to-brain-automation.sh import-path "$publish_brain/people/embed-retry.md" >/dev/null
grep -q "import $publish_brain/people/embed-retry.md --no-embed" "$GBRAIN_STUB_LOG" || fail "import-path did not import when embedding was disabled"
if grep -q "embed --stale" "$GBRAIN_STUB_LOG"; then
  fail "Embedding ran even though SOURCE_TO_BRAIN_EMBED_MODE=off"
fi

log "Verifying manifest path traversal is rejected"
cat > "$stage_dir/bad-manifest.json" <<'EOF'
{
  "operations": [
    {
      "type": "write",
      "target": "../escape.md",
      "source": "people/jane-doe.md"
    }
  ]
}
EOF
if ./scripts/source-to-brain-automation.sh apply-manifest "$publish_brain" "$stage_dir/bad-manifest.json" >/dev/null 2>&1; then
  fail "Path traversal manifest was accepted"
fi

if [[ "${RUN_NETWORK_TEST:-0}" == "1" ]]; then
  log "Running optional network clone test"
  git clone --depth 1 https://github.com/garrytan/gbrain.git "$tmp_root/network-gbrain" >/dev/null
  [[ -f "$tmp_root/network-gbrain/README.md" ]] || fail "Network gbrain clone did not produce README"
fi

log "All smoke tests passed"
