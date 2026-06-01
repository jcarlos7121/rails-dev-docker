#!/usr/bin/env bash
set -euo pipefail
# Adopt an existing Rails checkout into this wrapper via a symlink (no move/clone).
# Usage: .scripts/adopt.sh [-p <prefix>] <path-to-existing-checkout>

prefix=""
while getopts ":p:h" opt; do
  case "$opt" in
    p) prefix="$OPTARG" ;;
    h|*) echo "Usage: $0 [-p <prefix>] <app-path>" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

app_in="${1:?Usage: $0 [-p <prefix>] <app-path>}"
app_path="$(cd "$app_in" && pwd -P)"
[ -d "$app_path/.git" ] || { echo "Error: $app_path is not a git repo root" >&2; exit 1; }

root="$(cd "$(dirname "$0")/.." && pwd)"
base="$(basename "$app_path")"           # e.g. myapp — MUST match the real basename
prefix="${prefix:-$base}"

# --- Detect development DB name (best-effort; fallback to <prefix>_development) ---
dev_db="$(awk '/^[[:space:]]*development:/{f=1} f&&/database:/{sub(/.*database:[[:space:]]*/,"");gsub(/["'"'"' ]/,"");print;exit}' "$app_path/config/database.yml" 2>/dev/null || true)"
case "$dev_db" in ''|*'<%'*|*'ENV'*) dev_db="${prefix}_development" ;; esac
echo "Using DEV_DB_NAME=$dev_db"

# --- Root mise.local.toml (git-ignored) ---
cat > "$root/mise.local.toml" <<EOF
[env]
PROJECT_PREFIX = "$prefix"
GEM_VOLUME_BASE = "${prefix}_shared_gems"
NODE_MODULES_VOLUME = "${prefix}_shared_node_modules"
DEV_DB_NAME = "$dev_db"
NVIM_CONFIG_DIR = "$HOME/.config/nvim"
EOF
echo "Wrote $root/mise.local.toml"

# --- Symlink the base worktree ---
if [ -L "$root/$base" ] || [ -e "$root/$base" ]; then
  echo "Base '$root/$base' already exists, skipping symlink"
else
  ln -s "../$base" "$root/$base"
  echo "Linked $root/$base -> ../$base"
fi

# --- Locally ignore the generated per-worktree mise.local.toml in the real repo ---
excl="$app_path/.git/info/exclude"
grep -qxF 'mise.local.toml' "$excl" 2>/dev/null || echo 'mise.local.toml' >> "$excl"

# --- Ports registry (base = ID 0) ---
if [ -f "$root/ports.registry" ]; then
  echo "ports.registry exists, leaving as-is"
else
  echo "$base:0" > "$root/ports.registry"
  echo "Wrote ports.registry ($base:0)"
fi

# --- Render the base worktree's mise.local.toml from the template (WORKTREE_ID=0) ---
tmpl="$root/.mise/local.toml.template"
if [ -f "$tmpl" ] && [ ! -f "$app_path/mise.local.toml" ]; then
  sed 's|{{WORKTREE_ID}}|0|g' "$tmpl" > "$app_path/mise.local.toml"
  echo "Rendered $app_path/mise.local.toml (WORKTREE_ID=0)"
fi

mkdir -p "$app_path/node_modules"

# --- External docker volumes ---
for vol in claude_config claude_bashhistory "${prefix}_shared_node_modules"; do
  docker volume inspect "$vol" >/dev/null 2>&1 || docker volume create "$vol" >/dev/null
  echo "  volume $vol ready"
done

cat <<EOF

Adoption complete.
Next:
  cd $root && mise trust && mise install
  cd $root/$base && mise trust && mise install && mise run up
  App URL: http://$base.localhost
EOF
