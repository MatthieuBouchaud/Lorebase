#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install.sh [options]

Options:
  --brain <path>                    Brain repo path (default: ~/Brain)
  --gbrain <path>                   GBrain repo path (default: ~/gbrain)
  --model <model>                   Codex model for automations (default: gpt-5.4)
  --timezone <iana-zone>            Timezone written to config examples (default: Etc/UTC)
  --operator <name>                 Display name written to config examples
  --install-bun                     Install Bun with the official Bun installer if missing
  --no-gbrain-clone                 Do not clone gbrain if missing
  --no-install-codex-automations    Render automation TOML only; do not install paused automations
  --embed                           Run gbrain embed --stale even when OPENAI_API_KEY is not in the environment
  --no-embed                        Skip initial embedding
  -h, --help                        Show help
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
brain_repo="${BRAIN_REPO:-$HOME/Brain}"
gbrain_repo="${GBRAIN_REPO:-$HOME/gbrain}"
model="${CODEX_MODEL:-gpt-5.4}"
timezone="${TIMEZONE:-Etc/UTC}"
operator="${OPERATOR_DISPLAY_NAME:-Your Name}"
install_bun=0
clone_gbrain=1
install_codex_automations=1
embed_mode="${LOREBASE_INSTALL_EMBED_MODE:-auto}"

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
    --install-bun)
      install_bun=1
      shift
      ;;
    --no-gbrain-clone)
      clone_gbrain=0
      shift
      ;;
    --no-install-codex-automations)
      install_codex_automations=0
      shift
      ;;
    --embed)
      embed_mode="stale"
      shift
      ;;
    --no-embed)
      embed_mode="off"
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

for tool_dir in "$HOME/.bun/bin" "$HOME/.local/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
  if [[ -d "$tool_dir" && ":$PATH:" != *":$tool_dir:"* ]]; then
    PATH="$tool_dir:$PATH"
  fi
done
export PATH

ensure_bun() {
  if command -v bun >/dev/null 2>&1; then
    return 0
  fi
  if [[ "$install_bun" -ne 1 ]]; then
    cat >&2 <<'EOF'
Bun is required to install GBrain dependencies.
Re-run with --install-bun, or install Bun manually:
  curl -fsSL https://bun.sh/install | bash
EOF
    exit 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to install Bun automatically." >&2
    exit 1
  fi
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  if ! command -v bun >/dev/null 2>&1; then
    echo "Bun install finished, but bun is still not on PATH." >&2
    exit 1
  fi
}

bootstrap_args=(
  --brain "$brain_repo"
  --gbrain "$gbrain_repo"
  --model "$model"
  --timezone "$timezone"
  --operator "$operator"
)
if [[ "$clone_gbrain" -eq 0 ]]; then
  bootstrap_args+=(--no-gbrain-clone)
fi
if [[ "$install_codex_automations" -eq 1 ]]; then
  bootstrap_args+=(--install-codex-automations)
fi

"$script_dir/bootstrap.sh" "${bootstrap_args[@]}"

ensure_bun

(
  cd "$gbrain_repo"
  bun install
  bun link
)

if ! command -v gbrain >/dev/null 2>&1; then
  echo "Could not find gbrain after running bun link in $gbrain_repo." >&2
  exit 1
fi

gbrain init
gbrain doctor --json
gbrain import "$brain_repo" --no-embed

case "$embed_mode" in
  auto)
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
      gbrain embed --stale
    else
      echo "Skipped initial embeddings because OPENAI_API_KEY is not set."
      echo "After configuring it, run: gbrain embed --stale"
    fi
    ;;
  stale)
    gbrain embed --stale
    ;;
  off)
    echo "Skipped initial embeddings (--no-embed)."
    ;;
  *)
    echo "Unknown embed mode: $embed_mode" >&2
    exit 1
    ;;
esac

cat <<EOF

Lorebase install complete.

Brain repo:
  $brain_repo

GBrain/source-state repo:
  $gbrain_repo

Codex skill:
  $HOME/.codex/skills/source-to-brain-automation/SKILL.md

Paused automations:
  $HOME/.codex/automations

Next:
  Connect one Codex app at a time, verify its source config, then enable the matching paused automation.
EOF
