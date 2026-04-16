#!/usr/bin/env bash

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BINDIR=""
LIBEXECDIR=""
DATADIR=""
BASH_COMPLETION_DIR=""
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=0
PURGE_CONFIG=0

usage() {
  cat <<'EOF'
Usage: codexs-uninstall.sh [OPTIONS]

Remove codexs installed files.

Options:
  --prefix DIR                Installation prefix. Default: ~/.local
  --bindir DIR                Override binary installation directory
  --libexecdir DIR            Override helper script directory
  --datadir DIR               Override shared data directory
  --bash-completion-dir DIR   Override bash completion directory
  --config-home DIR           Override XDG config home. Default: $XDG_CONFIG_HOME or ~/.config
  --purge-config              Remove ~/.config/codex-launch/config and config.example
  --dry-run                   Print planned actions without deleting files
  -h, --help                  Show this help
EOF
}

log() {
  printf '%s\n' "$*"
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

remove_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    log "Remove $path"
    run rm -f "$path"
  else
    log "Skip missing $path"
  fi
}

remove_dir_if_empty() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    if (( DRY_RUN )); then
      printf '[dry-run] rmdir --ignore-fail-on-non-empty %s\n' "$dir"
    else
      rmdir --ignore-fail-on-non-empty "$dir" 2>/dev/null || true
    fi
  fi
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
    --purge-config)
      PURGE_CONFIG=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

remove_file "$BINDIR/codexs"
remove_file "$LIBEXECDIR/codexs-picker"
remove_file "$BASH_COMPLETION_DIR/codexs"
remove_file "$DATADIR/config.example"
remove_file "$CONFIG_HOME/codex-launch/config.example"

if (( PURGE_CONFIG )); then
  remove_file "$CONFIG_HOME/codex-launch/config"
fi

remove_dir_if_empty "$LIBEXECDIR"
remove_dir_if_empty "$DATADIR"
remove_dir_if_empty "$PREFIX/share/bash-completion/completions"
remove_dir_if_empty "$PREFIX/share/bash-completion"
remove_dir_if_empty "$PREFIX/share"
remove_dir_if_empty "$PREFIX/libexec"
remove_dir_if_empty "$CONFIG_HOME/codex-launch"

log "Uninstall complete."
