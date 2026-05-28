#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  render-codex-templates.sh --brain <path> --gbrain <path> [--model <model>] [--output <dir>]
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
starter_root="$(cd "$script_dir/.." && pwd)"
brain_repo="${BRAIN_REPO:-$HOME/Brain}"
gbrain_repo="${GBRAIN_REPO:-$HOME/gbrain}"
model="${CODEX_MODEL:-gpt-5.4}"
output_dir="$starter_root/generated/codex-automations"

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
    --output)
      output_dir="$2"
      shift 2
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

mkdir -p "$output_dir"

skill_path="$HOME/.codex/skills/source-to-brain-automation/SKILL.md"

python3 - "$starter_root" "$brain_repo" "$gbrain_repo" "$skill_path" "$model" "$output_dir" <<'PY'
import pathlib
import sys

starter_root, brain_repo, gbrain_repo, skill_path, model, output_dir = sys.argv[1:]
template_dir = pathlib.Path(starter_root) / "automation-templates" / "codex"
out_dir = pathlib.Path(output_dir)
replacements = {
    "{{STARTER_REPO}}": str(pathlib.Path(starter_root).expanduser()),
    "{{BRAIN_REPO}}": str(pathlib.Path(brain_repo).expanduser()),
    "{{GBRAIN_REPO}}": str(pathlib.Path(gbrain_repo).expanduser()),
    "{{CODEX_SKILL_PATH}}": str(pathlib.Path(skill_path).expanduser()),
    "{{MODEL}}": model,
}

for template in template_dir.glob("*.toml.template"):
    text = template.read_text()
    for key, value in replacements.items():
        text = text.replace(key, value)
    target = out_dir / template.name[:-len(".template")]
    target.write_text(text)
    print(f"rendered {target}")
PY
