#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh [options]

Options:
  --brain <path>                 Brain repo path (default: ~/Brain)
  --gbrain <path>                GBrain repo path (default: ~/gbrain)
  --model <model>                Codex model for automations (default: gpt-5.4)
  --timezone <iana-zone>         Timezone written to config examples (default: Etc/UTC)
  --operator <name>              Display name written to config examples
  --no-gbrain-clone              Do not clone gbrain if missing
  --no-install-codex-skill       Do not install the Codex skill template
  --install-codex-automations    Copy rendered paused automations into ~/.codex/automations
  -h, --help                     Show help
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
starter_root="$(cd "$script_dir/.." && pwd)"

brain_repo="${BRAIN_REPO:-$HOME/Brain}"
gbrain_repo="${GBRAIN_REPO:-$HOME/gbrain}"
model="${CODEX_MODEL:-gpt-5.4}"
timezone="${TIMEZONE:-Etc/UTC}"
operator="${OPERATOR_DISPLAY_NAME:-Your Name}"
clone_gbrain=1
install_codex_skill=1
install_codex_automations=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brain)
      brain_repo="$2"
      shift 2
      ;;
    --gbrain)
      gbrain_repo="$2"
      shift 2
      ;;
    --model)
      model="$2"
      shift 2
      ;;
    --timezone)
      timezone="$2"
      shift 2
      ;;
    --operator)
      operator="$2"
      shift 2
      ;;
    --no-gbrain-clone)
      clone_gbrain=0
      shift
      ;;
    --no-install-codex-skill)
      install_codex_skill=0
      shift
      ;;
    --install-codex-automations)
      install_codex_automations=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

copy_tree_no_overwrite() {
  local src="$1"
  local dst="$2"
  python3 - "$src" "$dst" <<'PY'
import pathlib
import shutil
import sys

src = pathlib.Path(sys.argv[1]).resolve()
dst = pathlib.Path(sys.argv[2]).expanduser().resolve()
dst.mkdir(parents=True, exist_ok=True)

for path in src.rglob("*"):
    rel = path.relative_to(src)
    target = dst / rel
    if path.is_dir():
        target.mkdir(parents=True, exist_ok=True)
    elif not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        print(f"created {target}")
PY
}

render_text_template() {
  local src="$1"
  local dst="$2"
  python3 - "$src" "$dst" "$starter_root" "$brain_repo" "$gbrain_repo" "$model" "$timezone" "$operator" <<'PY'
import pathlib
import sys

src, dst, starter_root, brain_repo, gbrain_repo, model, timezone, operator = sys.argv[1:]
text = pathlib.Path(src).read_text()
replacements = {
    "{{STARTER_REPO}}": str(pathlib.Path(starter_root).expanduser()),
    "{{BRAIN_REPO}}": str(pathlib.Path(brain_repo).expanduser()),
    "{{GBRAIN_REPO}}": str(pathlib.Path(gbrain_repo).expanduser()),
    "{{MODEL}}": model,
    "{{TIMEZONE}}": timezone,
    "{{OPERATOR_DISPLAY_NAME}}": operator,
}
for key, value in replacements.items():
    text = text.replace(key, value)
target = pathlib.Path(dst).expanduser()
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(text)
print(f"wrote {target}")
PY
}

copy_json_example() {
  local src="$1"
  local dst="$2"
  python3 - "$src" "$dst" "$timezone" "$operator" <<'PY'
import json
import pathlib
import sys

src, dst, timezone, operator = sys.argv[1:]
source = pathlib.Path(src)
target = pathlib.Path(dst).expanduser()
if target.exists():
    print(f"kept existing {target}")
    raise SystemExit(0)

data = json.loads(source.read_text())
if isinstance(data, dict):
    if "timezone" in data:
        data["timezone"] = timezone
    if "operator_display_name" in data:
        data["operator_display_name"] = operator
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(data, indent=2) + "\n")
print(f"created {target}")
PY
}

echo "Lorebase bootstrap"
echo "starter: $starter_root"
echo "brain:   $brain_repo"
echo "gbrain:  $gbrain_repo"

if [[ "$clone_gbrain" -eq 1 && ! -d "$gbrain_repo/.git" ]]; then
  echo "Cloning gbrain into $gbrain_repo"
  git clone https://github.com/garrytan/gbrain.git "$gbrain_repo"
fi

mkdir -p "$brain_repo"
copy_tree_no_overwrite "$starter_root/brain-template" "$brain_repo"

if [[ ! -d "$brain_repo/.git" ]]; then
  git -C "$brain_repo" init --initial-branch=main >/dev/null 2>&1 || git -C "$brain_repo" init
fi

if [[ "$install_codex_skill" -eq 1 ]]; then
  render_text_template \
    "$starter_root/automation-templates/codex/source-to-brain-automation.SKILL.md.template" \
    "$HOME/.codex/skills/source-to-brain-automation/SKILL.md"
fi

"$starter_root/scripts/render-codex-templates.sh" \
  --brain "$brain_repo" \
  --gbrain "$gbrain_repo" \
  --model "$model" \
  --output "$starter_root/generated/codex-automations"

if [[ -d "$gbrain_repo" ]]; then
  copy_json_example "$starter_root/config/email-sync.config.example.json" "$gbrain_repo/email-sync/config.example.json"
  copy_json_example "$starter_root/config/calendar-sync.config.example.json" "$gbrain_repo/calendar-sync/config.example.json"
  copy_json_example "$starter_root/config/slack-sync.config.example.json" "$gbrain_repo/slack-sync/config.example.json"
  copy_json_example "$starter_root/config/notion-meetings-sync.config.example.json" "$gbrain_repo/notion-meetings-sync/config.example.json"
  copy_json_example "$starter_root/config/telegram-sync.config.example.json" "$gbrain_repo/telegram-sync/config.example.json"
fi

if [[ "$install_codex_automations" -eq 1 ]]; then
  for toml in "$starter_root"/generated/codex-automations/*.toml; do
    id="$(basename "$toml" .toml)"
    mkdir -p "$HOME/.codex/automations/$id"
    cp "$toml" "$HOME/.codex/automations/$id/automation.toml"
    echo "installed paused automation $id"
  done
fi

if [[ -d "$gbrain_repo" ]]; then
  if command -v bun >/dev/null 2>&1; then
    bun_step=""
  else
    bun_step="  curl -fsSL https://bun.sh/install | bash
  export PATH=\"\$HOME/.bun/bin:\$PATH\"
"
  fi
  gbrain_next_steps="${bun_step}  cd \"$gbrain_repo\"
  bun install
  bun link
  gbrain init
  gbrain doctor --json
  gbrain import \"$brain_repo\" --no-embed
  # After configuring OPENAI_API_KEY, run:
  # gbrain embed --stale"
else
  gbrain_next_steps="  Clone or choose a GBrain repo, then re-run bootstrap without --no-gbrain-clone or with --gbrain <path>."
fi

cat <<EOF

Done.

Next:
$gbrain_next_steps

Rendered paused Codex automations:
  $starter_root/generated/codex-automations

Enable one source at a time after its connector and config are verified.
EOF
