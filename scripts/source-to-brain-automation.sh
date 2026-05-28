#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  source-to-brain-automation.sh doctor
  source-to-brain-automation.sh write-set <source-id>
  source-to-brain-automation.sh read-file <repo-path> <relative-path>
  source-to-brain-automation.sh list-dir <repo-path> <relative-dir-or-empty>
  source-to-brain-automation.sh apply-manifest <repo-path> <manifest-path>
  source-to-brain-automation.sh publish-manifest <repo-path> <manifest-path>
  source-to-brain-automation.sh check-clean-paths <repo-path> <path> [<path>...]
  source-to-brain-automation.sh commit-files <repo-path> <commit-message> <path> [<path>...]
  source-to-brain-automation.sh commit-source-split <source-id> <code-repo-path> <brain-repo-path> <commit-message>
  source-to-brain-automation.sh sync-repo <repo-path>
  source-to-brain-automation.sh import-path <import-path>
  source-to-brain-automation.sh heartbeat --integration <id> --status <status> [--details <text>] [--counts <json>] [--extra-json <json>]
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

command_name="$1"
shift
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
starter_root="$(cd "$script_dir/.." && pwd)"
write_set_file="${SOURCE_TO_BRAIN_WRITE_SETS:-$starter_root/config/source-write-sets.json}"
embed_mode="${SOURCE_TO_BRAIN_EMBED_MODE:-stale}"
embed_required="${SOURCE_TO_BRAIN_REQUIRE_EMBEDDINGS:-0}"

for tool_dir in "$HOME/.bun/bin" "$HOME/.local/bin" "/opt/homebrew/bin" "/usr/local/bin"; do
  if [[ -d "$tool_dir" && ":$PATH:" != *":$tool_dir:"* ]]; then
    PATH="$tool_dir:$PATH"
  fi
done
export PATH

resolve_gbrain_bin() {
  if [[ -n "${GBRAIN_BIN:-}" && -x "${GBRAIN_BIN:-}" ]]; then
    printf '%s\n' "$GBRAIN_BIN"
    return 0
  fi
  if command -v gbrain >/dev/null 2>&1; then
    command -v gbrain
    return 0
  fi
  echo "Could not find gbrain. Set GBRAIN_BIN or add gbrain to PATH." >&2
  exit 1
}

embed_stale_brain() {
  case "$embed_mode" in
    off|false|0)
      echo "embedding skipped (SOURCE_TO_BRAIN_EMBED_MODE=$embed_mode)"
      return 0
      ;;
    stale|"")
      ;;
    *)
      echo "Unknown SOURCE_TO_BRAIN_EMBED_MODE: $embed_mode" >&2
      exit 1
      ;;
  esac

  local gbrain_bin
  gbrain_bin="$(resolve_gbrain_bin)"
  if GBRAIN_EMBED_CONCURRENCY="${GBRAIN_EMBED_CONCURRENCY:-4}" "$gbrain_bin" embed --stale; then
    return 0
  fi

  if [[ "$embed_required" == "1" || "$embed_required" == "true" ]]; then
    echo "embedding failed and SOURCE_TO_BRAIN_REQUIRE_EMBEDDINGS=$embed_required" >&2
    return 1
  fi

  echo "embedding failed; text import/sync already completed. Configure OPENAI_API_KEY or run 'gbrain embed --stale' later." >&2
  return 0
}

require_node() {
  if ! command -v node >/dev/null 2>&1; then
    echo "node is required for JSON manifest handling." >&2
    exit 1
  fi
}

assert_inside_repo() {
  local repo_path="$1"
  local rel_path="$2"
  node - "$repo_path" "$rel_path" <<'NODE'
const path = require('path');
const [repoPath, relPath] = process.argv.slice(2);
if (path.isAbsolute(relPath)) {
  console.error(`Expected relative path, got absolute path: ${relPath}`);
  process.exit(1);
}
const repo = path.resolve(repoPath);
const target = path.resolve(repo, relPath || '.');
if (target !== repo && !target.startsWith(repo + path.sep)) {
  console.error(`Path escapes repo: ${relPath}`);
  process.exit(1);
}
NODE
}

json_write_set() {
  local source_id="$1"
  require_node
  node - "$write_set_file" "$source_id" <<'NODE'
const fs = require('fs');
const [filePath, sourceId] = process.argv.slice(2);
const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
const source = data.sources?.[sourceId];

if (!source) {
  console.error(JSON.stringify({
    status: 'error',
    reason: 'unknown_source_id',
    source_id: sourceId,
    known_sources: Object.keys(data.sources || {}),
  }));
  process.exit(1);
}

process.stdout.write(JSON.stringify({
  status: 'ok',
  source_id: sourceId,
  code_repo_paths: source.code_repo_paths || [],
  brain_repo_paths: source.brain_repo_paths || [],
  commit_paths: [
    ...(source.code_repo_paths || []),
    ...(source.brain_repo_paths || []),
  ],
  ...source,
}, null, 2) + '\n');
NODE
}

status_for_paths() {
  local repo_path="$1"
  shift
  if [[ ! -d "$repo_path/.git" ]]; then
    echo ""
    return 0
  fi
  git -C "$repo_path" status --porcelain=v1 -- "$@"
}

commit_if_dirty() {
  local repo_path="$1"
  local message="$2"
  shift 2
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "skip commit: $repo_path is not a git repo"
    return 0
  fi
  local status_output
  status_output="$(status_for_paths "$repo_path" "$@")"
  if [[ -z "$status_output" ]]; then
    echo "no changes to commit in $repo_path"
    return 0
  fi
  git -C "$repo_path" add -- "$@"
  git -C "$repo_path" commit -m "$message"
}

case "$command_name" in
  doctor)
    gbrain_bin="$(resolve_gbrain_bin)"
    "$gbrain_bin" doctor --json
    ;;

  write-set)
    if [[ $# -ne 1 ]]; then
      usage >&2
      exit 1
    fi
    json_write_set "$1"
    ;;

  read-file)
    if [[ $# -ne 2 ]]; then
      usage >&2
      exit 1
    fi
    repo_path="$1"
    rel_path="$2"
    assert_inside_repo "$repo_path" "$rel_path"
    cat "$repo_path/$rel_path"
    ;;

  list-dir)
    if [[ $# -ne 2 ]]; then
      usage >&2
      exit 1
    fi
    repo_path="$1"
    rel_path="$2"
    assert_inside_repo "$repo_path" "$rel_path"
    find "$repo_path/$rel_path" -maxdepth 1 -mindepth 1 -print | sort
    ;;

  apply-manifest)
    if [[ $# -ne 2 ]]; then
      usage >&2
      exit 1
    fi
    require_node
    repo_path="$1"
    manifest_path="$2"
    node - "$repo_path" "$manifest_path" <<'NODE'
const fs = require('fs');
const path = require('path');

const [repoPath, manifestPath] = process.argv.slice(2);
const repo = path.resolve(repoPath);
const manifestFile = path.resolve(manifestPath);
const manifestDir = path.dirname(manifestFile);
const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
const operations = manifest.operations || [];
const changed = [];

function resolveTarget(rel) {
  if (!rel || path.isAbsolute(rel)) throw new Error(`Invalid target path: ${rel}`);
  const target = path.resolve(repo, rel);
  if (target !== repo && !target.startsWith(repo + path.sep)) {
    throw new Error(`Target escapes repo: ${rel}`);
  }
  return target;
}

for (const op of operations) {
  if (op.type === 'write') {
    const target = resolveTarget(op.target);
    const source = path.isAbsolute(op.source)
      ? path.resolve(op.source)
      : path.resolve(manifestDir, op.source);
    if (!source.startsWith(manifestDir + path.sep) && source !== manifestDir) {
      throw new Error(`Source escapes manifest dir: ${op.source}`);
    }
    const next = fs.readFileSync(source);
    const previous = fs.existsSync(target) ? fs.readFileSync(target) : null;
    if (!previous || !previous.equals(next)) {
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, next);
      changed.push({ type: 'write', target: op.target });
    }
  } else if (op.type === 'delete') {
    const target = resolveTarget(op.target);
    if (fs.existsSync(target)) {
      fs.rmSync(target, { recursive: true, force: true });
      changed.push({ type: 'delete', target: op.target });
    }
  } else {
    throw new Error(`Unknown operation type: ${op.type}`);
  }
}

process.stdout.write(JSON.stringify({ status: 'ok', changed }, null, 2) + '\n');
NODE
    ;;

  publish-manifest)
    if [[ $# -ne 2 ]]; then
      usage >&2
      exit 1
    fi
    require_node
    repo_path="$1"
    manifest_path="$2"
    result_json="$("$0" apply-manifest "$repo_path" "$manifest_path")"
    echo "$result_json"
    changed_count="$(node -e 'const fs=require("fs"); const j=JSON.parse(fs.readFileSync(0,"utf8")); console.log((j.changed||[]).length)' <<<"$result_json")"
    if [[ "$changed_count" == "0" ]]; then
      echo "publish-manifest: no changes; skipping import/sync"
      exit 0
    fi
    has_delete="$(node -e 'const fs=require("fs"); const j=JSON.parse(fs.readFileSync(0,"utf8")); console.log((j.changed||[]).some(x=>x.type==="delete") ? "yes" : "no")' <<<"$result_json")"
    gbrain_bin="$(resolve_gbrain_bin)"
    if [[ "$has_delete" == "yes" ]]; then
      "$gbrain_bin" sync --repo "$repo_path" --no-pull --no-embed
    else
      node -e 'const fs=require("fs"); const path=require("path"); const repo=process.argv[1]; const j=JSON.parse(fs.readFileSync(0,"utf8")); for (const c of j.changed||[]) if (c.type==="write") console.log(path.join(repo,c.target));' "$repo_path" <<<"$result_json" |
      while IFS= read -r import_path; do
        [[ -n "$import_path" ]] && "$gbrain_bin" import "$import_path" --no-embed
      done
    fi
    embed_stale_brain
    ;;

  check-clean-paths)
    if [[ $# -lt 2 ]]; then
      usage >&2
      exit 1
    fi
    repo_path="$1"
    shift
    status_output="$(status_for_paths "$repo_path" "$@")"
    if [[ -n "$status_output" ]]; then
      echo "$status_output" >&2
      exit 1
    fi
    echo "clean"
    ;;

  commit-files)
    if [[ $# -lt 3 ]]; then
      usage >&2
      exit 1
    fi
    repo_path="$1"
    message="$2"
    shift 2
    commit_if_dirty "$repo_path" "$message" "$@"
    ;;

  commit-source-split)
    if [[ $# -ne 4 ]]; then
      usage >&2
      exit 1
    fi
    source_id="$1"
    code_repo="$2"
    brain_repo="$3"
    message="$4"
    require_node
    write_set_json="$(json_write_set "$source_id")"
    code_paths=()
    while IFS= read -r path_item; do
      [[ -n "$path_item" ]] && code_paths+=("$path_item")
    done < <(node -e 'const fs=require("fs"); const j=JSON.parse(fs.readFileSync(0,"utf8")); for (const p of j.code_repo_paths||[]) console.log(p)' <<<"$write_set_json")
    brain_paths=()
    while IFS= read -r path_item; do
      [[ -n "$path_item" ]] && brain_paths+=("$path_item")
    done < <(node -e 'const fs=require("fs"); const j=JSON.parse(fs.readFileSync(0,"utf8")); for (const p of j.brain_repo_paths||[]) console.log(p)' <<<"$write_set_json")
    if [[ "${#code_paths[@]}" -gt 0 ]]; then
      commit_if_dirty "$code_repo" "$message" "${code_paths[@]}"
    fi
    if [[ "${#brain_paths[@]}" -gt 0 ]]; then
      commit_if_dirty "$brain_repo" "$message" "${brain_paths[@]}"
    fi
    ;;

  sync-repo)
    if [[ $# -ne 1 ]]; then
      usage >&2
      exit 1
    fi
    gbrain_bin="$(resolve_gbrain_bin)"
    "$gbrain_bin" sync --repo "$1" --no-pull --no-embed
    embed_stale_brain
    ;;

  import-path)
    if [[ $# -ne 1 ]]; then
      usage >&2
      exit 1
    fi
    gbrain_bin="$(resolve_gbrain_bin)"
    "$gbrain_bin" import "$1" --no-embed
    embed_stale_brain
    ;;

  heartbeat)
    integration=""
    status=""
    details=""
    counts="{}"
    extra_json="{}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --integration)
          integration="$2"
          shift 2
          ;;
        --status)
          status="$2"
          shift 2
          ;;
        --details)
          details="$2"
          shift 2
          ;;
        --counts)
          counts="$2"
          shift 2
          ;;
        --extra-json)
          extra_json="$2"
          shift 2
          ;;
        *)
          echo "Unknown heartbeat argument: $1" >&2
          exit 1
          ;;
      esac
    done
    if [[ -z "$integration" || -z "$status" ]]; then
      echo "heartbeat requires --integration and --status" >&2
      exit 1
    fi
    require_node
    mkdir -p "$HOME/.gbrain/integrations/$integration"
    node - "$integration" "$status" "$details" "$counts" "$extra_json" >> "$HOME/.gbrain/integrations/$integration/heartbeat.jsonl" <<'NODE'
const [integration, status, details, countsRaw, extraRaw] = process.argv.slice(2);
let counts = {};
let extra = {};
try { counts = JSON.parse(countsRaw || '{}'); } catch {}
try { extra = JSON.parse(extraRaw || '{}'); } catch {}
process.stdout.write(JSON.stringify({
  integration,
  status,
  details,
  counts,
  ...extra,
  at: new Date().toISOString(),
}) + '\n');
NODE
    echo "heartbeat written for $integration"
    ;;

  -h|--help)
    usage
    ;;

  *)
    echo "Unknown command: $command_name" >&2
    usage >&2
    exit 1
    ;;
esac
