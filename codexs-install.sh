#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${PREFIX:-$HOME/.local}"
BINDIR=""
LIBEXECDIR=""
DATADIR=""
BASH_COMPLETION_DIR=""
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=0
VERIFY=0
FORCE_CONFIG=0
declare -a PINNED_DIRS=("~/foo-project-a" "~/foo-project-b")
declare -a WORKSPACE_ROOTS=("~/foo-workspace")

usage() {
  cat <<'EOF'
Usage: codexs-install.sh [OPTIONS]

Install codexs using Linux-style prefix paths.

Options:
  --prefix DIR                Install prefix. Default: ~/.local
  --bindir DIR                Override binary installation directory
  --libexecdir DIR            Override helper script directory
  --datadir DIR               Override shared data directory
  --bash-completion-dir DIR   Override bash completion directory
  --config-home DIR           Override XDG config home. Default: $XDG_CONFIG_HOME or ~/.config
  --project-dir PATH          Add an initial pinned project path (repeatable)
  --workspace-root PATH       Add a workspace root path (repeatable)
  --force-config              Overwrite existing user config
  --dry-run                   Print planned actions without copying files
  --verify                    Verify installed files after installation
  -h, --help                  Show this help
EOF
}

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

run() {
  if (( DRY_RUN )); then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

set_defaults() {
  [[ -n "$BINDIR" ]] || BINDIR="$PREFIX/bin"
  [[ -n "$LIBEXECDIR" ]] || LIBEXECDIR="$PREFIX/libexec/codexs"
  [[ -n "$DATADIR" ]] || DATADIR="$PREFIX/share/codexs"
  [[ -n "$BASH_COMPLETION_DIR" ]] || BASH_COMPLETION_DIR="$PREFIX/share/bash-completion/completions"
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$cmd" >&2
    exit 1
  }
}

detect_environment() {
  require_command bash
  require_command python3
  require_command install
  require_command sed
  python3 - <<'PY' >/dev/null
import curses
import sqlite3
PY

  if ! command -v codex >/dev/null 2>&1; then
    warn "codex CLI not found in PATH. The launcher will install, but it will not run until codex is installed."
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    warn "fzf not found in PATH. codexs will fall back to whiptail or plain terminal selection."
  fi
  if ! command -v whiptail >/dev/null 2>&1; then
    warn "whiptail not found in PATH. Without fzf, codexs will use plain terminal selection."
  fi
}

check_path_hint() {
  case ":$PATH:" in
    *":$BINDIR:"*) ;;
    *)
      warn "$BINDIR is not in PATH. Add it to your shell profile if you want to run codexs directly."
      ;;
  esac
}

verify_writable_parent() {
  local path="$1"
  local parent
  parent="$(dirname "$path")"
  while [[ ! -d "$parent" && "$parent" != "/" ]]; do
    parent="$(dirname "$parent")"
  done
  [[ -w "$parent" ]] || {
    printf 'Target is not writable: %s\n' "$path" >&2
    exit 1
  }
}

append_unique() {
  local -n ref=$1
  local value="$2"
  local existing
  for existing in "${ref[@]}"; do
    [[ "$existing" == "$value" ]] && return 0
  done
  ref+=("$value")
}

render_array_items() {
  local item
  for item in "$@"; do
    printf '%q ' "$item"
  done
}

render_template() {
  local src="$1"
  local pinned workspace
  pinned="$(render_array_items "${PINNED_DIRS[@]}")"
  workspace="$(render_array_items "${WORKSPACE_ROOTS[@]}")"
  sed \
    -e "s|__PINNED_DIRS__|$pinned|g" \
    -e "s|__WORKSPACE_ROOTS__|$workspace|g" \
    "$src"
}

install_rendered_template() {
  local src_rel="$1"
  local dest="$2"
  local mode="$3"
  local src="$SCRIPT_DIR/$src_rel"

  [[ -f "$src" ]] || {
    printf 'Missing source file: %s\n' "$src" >&2
    exit 1
  }

  run mkdir -p "$(dirname "$dest")"
  log "Install $src_rel -> $dest"
  if (( DRY_RUN )); then
    printf '[dry-run] render template %s -> %s\n' "$src" "$dest"
    return 0
  fi
  render_template "$src" | install -m "$mode" /dev/stdin "$dest"
}

install_file() {
  local src_rel="$1"
  local dest="$2"
  local mode="$3"
  local src="$SCRIPT_DIR/$src_rel"

  [[ -f "$src" ]] || {
    printf 'Missing source file: %s\n' "$src" >&2
    exit 1
  }

  run mkdir -p "$(dirname "$dest")"
  log "Install $src_rel -> $dest"
  run install -m "$mode" "$src" "$dest"
}

install_configs() {
  local template_rel="share/codexs/config.example"
  local config_dir="$CONFIG_HOME/codex-launch"
  local example_dest="$config_dir/config.example"
  local config_dest="$config_dir/config"

  install_rendered_template "$template_rel" "$example_dest" 0644

  if (( FORCE_CONFIG )) || [[ ! -e "$config_dest" ]]; then
    if [[ -e "$config_dest" ]]; then
      log "Overwrite existing config: $config_dest"
    else
      log "Install default config from template -> $config_dest"
    fi
    install_rendered_template "$template_rel" "$config_dest" 0644
  else
    log "Keep existing config: $config_dest"
  fi
}

verify_file() {
  local path="$1"
  [[ -e "$path" ]] || {
    printf 'Missing installed file: %s\n' "$path" >&2
    exit 1
  }
  log "Verified $path"
}

verify_contains() {
  local path="$1"
  local needle="$2"
  rg -Fq "$needle" "$path" || {
    printf 'Verification failed for %s: missing %s\n' "$path" "$needle" >&2
    exit 1
  }
  log "Verified content in $path"
}

while (( $# > 0 )); do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --bindir)
      BINDIR="$2"
      shift 2
      ;;
    --libexecdir)
      LIBEXECDIR="$2"
      shift 2
      ;;
    --datadir)
      DATADIR="$2"
      shift 2
      ;;
    --bash-completion-dir)
      BASH_COMPLETION_DIR="$2"
      shift 2
      ;;
    --config-home)
      CONFIG_HOME="$2"
      shift 2
      ;;
    --project-dir)
      if (( ${#PINNED_DIRS[@]} == 2 )) && [[ "${PINNED_DIRS[0]}" == "~/foo-project-a" ]] && [[ "${PINNED_DIRS[1]}" == "~/foo-project-b" ]]; then
        PINNED_DIRS=()
      fi
      append_unique PINNED_DIRS "$2"
      shift 2
      ;;
    --workspace-root)
      if (( ${#WORKSPACE_ROOTS[@]} == 1 )) && [[ "${WORKSPACE_ROOTS[0]}" == "~/foo-workspace" ]]; then
        WORKSPACE_ROOTS=()
      fi
      append_unique WORKSPACE_ROOTS "$2"
      shift 2
      ;;
    --force-config)
      FORCE_CONFIG=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verify)
      VERIFY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

set_defaults
detect_environment
check_path_hint

verify_writable_parent "$BINDIR/codexs"
verify_writable_parent "$LIBEXECDIR/codexs-picker"
verify_writable_parent "$DATADIR/config.example"
verify_writable_parent "$BASH_COMPLETION_DIR/codexs"
verify_writable_parent "$CONFIG_HOME/codex-launch/config"

install_file "bin/codexs" "$BINDIR/codexs" 0755
install_file "libexec/codexs/codexs-picker" "$LIBEXECDIR/codexs-picker" 0755
install_file "share/bash-completion/completions/codexs" "$BASH_COMPLETION_DIR/codexs" 0644
install_rendered_template "share/codexs/config.example" "$DATADIR/config.example" 0644
install_configs

if (( VERIFY )); then
  if (( DRY_RUN )); then
    log "Skip verification during dry-run."
  else
    verify_file "$BINDIR/codexs"
    verify_file "$LIBEXECDIR/codexs-picker"
    verify_file "$BASH_COMPLETION_DIR/codexs"
    verify_file "$DATADIR/config.example"
    verify_file "$CONFIG_HOME/codex-launch/config.example"
    verify_contains "$BINDIR/codexs" 'cd "$selected_dir"'
    verify_contains "$CONFIG_HOME/codex-launch/config.example" "PINNED_DIRS="
    verify_contains "$CONFIG_HOME/codex-launch/config.example" "WORKSPACE_ROOTS="
  fi
fi

log "Install complete."
