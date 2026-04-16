# codexs

[中文文档](./README.zh-CN.md)

`codexs` is a project-aware launcher for the OpenAI Codex CLI, built for Linux terminal workflows with no GUI. Its purpose is to reduce the friction of multi-project Codex development on headless or remote Linux machines: choosing the right project directory, resuming the right session, and keeping project path management simple from the command line.

It is especially useful today in environments where development happens directly in Linux shells, and it remains useful as a lightweight workflow even before future desktop-side remote Linux support becomes standard.

## What Problem It Solves

When you use Codex across many repositories in a Linux terminal-only environment, the default workflow becomes repetitive:

- you need to remember the correct project path
- you need to `cd` manually before launching
- you want resume history scoped to the current project
- you want a repeatable way to manage project directories across multiple repos
- you want one launcher that works well on headless Linux over SSH, tmux, or terminal multiplexers

`codexs` wraps those problems into one consistent workflow.

## Features

- Launch Codex in a selected project directory
- Scope resume choices to the selected project
- Keep process `cwd` and Codex `-C` aligned so interactive `/resume` behaves correctly
- Default to `--yolo`, but disable it automatically when `--sandbox` is explicitly passed
- Support multiple pickers: curses, `fzf`, `whiptail`, and plain terminal fallback
- Manage configured project paths with `codexs repo list|add|remove`
- Install cleanly with Linux-style `prefix/bin/libexec/share` layout
- Generate user config under XDG config directories

## Repository Layout

```text
.
├── bin/codexs
├── libexec/codexs/codexs-picker
├── share/bash-completion/completions/codexs
├── share/codexs/config.example
├── codexs-install.sh
├── codexs-uninstall.sh
├── INSTALL.md
├── README.md
├── README.zh-CN.md
├── LICENSE
└── .gitignore
```

## Requirements

Required:

- Linux
- `bash`
- `python3`
- OpenAI `codex` CLI installed and available in `PATH`

Optional:

- `fzf` is strongly recommended and should normally be installed by default for the best picker experience
- `whiptail` as a fallback picker

Session resume also depends on local Codex state files such as:

- `~/.codex/state_5.sqlite`
- `~/.codex/sessions`
- `~/.codex/session_index.jsonl`
- `~/.codex/history.jsonl`

## Installation

Default user install:

```bash
./codexs-install.sh
```

Install and verify:

```bash
./codexs-install.sh --verify
```

Preview the install plan:

```bash
./codexs-install.sh --dry-run --verify
```

Set initial project paths during installation:

```bash
./codexs-install.sh \
  --project-dir ~/foo-project-a \
  --project-dir ~/foo-project-b \
  --workspace-root ~/foo-workspace
```

Useful installer options:

- `--prefix DIR`
- `--bindir DIR`
- `--libexecdir DIR`
- `--datadir DIR`
- `--bash-completion-dir DIR`
- `--config-home DIR`
- `--project-dir PATH`
- `--workspace-root PATH`
- `--force-config`

### Installed Paths

With the default prefix, files are installed to:

- `~/.local/bin/codexs`
- `~/.local/libexec/codexs/codexs-picker`
- `~/.local/share/bash-completion/completions/codexs`
- `~/.local/share/codexs/config.example`
- `~/.config/codex-launch/config.example`

If `~/.config/codex-launch/config` does not exist, the installer creates it from the template. If it already exists, it is preserved unless `--force-config` is used.

## Guided Agent Install

If another Codex instance is helping the user install this tool, start with [INSTALL.md](./INSTALL.md).

That document tells the agent to:

- inspect dependencies
- ask the user about project paths and workspace roots
- ask whether an existing config should be preserved
- explain missing dependencies and install implications
- run a dry-run before the real install

## Uninstall

Preview uninstall actions:

```bash
./codexs-uninstall.sh --dry-run
```

Remove installed launcher files:

```bash
./codexs-uninstall.sh
```

Remove launcher files and user config:

```bash
./codexs-uninstall.sh --purge-config
```

## Shell Setup

Make sure your binary directory is in `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To enable bash completion:

```bash
source "$HOME/.local/share/bash-completion/completions/codexs"
```

## Basic Usage

Interactive project picker:

```bash
codexs
```

Launch directly in a project:

```bash
codexs ~/foo-workspace/foo-project
```

Force resume:

```bash
codexs --resume
```

Force a new session:

```bash
codexs --no-resume
```

Pass extra Codex arguments:

```bash
codexs ~/foo-workspace/foo-project -- --search
```

Disable default `--yolo` by explicitly requesting a sandbox:

```bash
codexs ~/foo-workspace/foo-project --sandbox workspace-write
```

## Project Path Management

`codexs repo` manages project paths stored in the user config.

Show configured project paths and workspace roots:

```bash
codexs repo list
```

Add one or more pinned project paths:

```bash
codexs repo add ~/foo-project-a ~/foo-project-b
```

Remove one or more pinned project paths:

```bash
codexs repo remove ~/foo-project-a
```

These commands update:

- `PINNED_DIRS`
- `WORKSPACE_ROOTS` is shown by `repo list`, but still initialized through config or installer options

## Configuration

User config path:

```text
~/.config/codex-launch/config
```

Example:

```bash
# AUTO_RESUME=ask|always|never
AUTO_RESUME=ask
RECENT_LIMIT=10
DEFAULT_YOLO=1

PINNED_DIRS=(~/foo-project-a ~/foo-project-b)
WORKSPACE_ROOTS=(~/foo-workspace)
```

Supported settings:

- `AUTO_RESUME`
- `RECENT_LIMIT`
- `DEFAULT_YOLO`
- `FZF_OPTS`
- `NEWT_COLORS`
- `PINNED_DIRS`
- `WORKSPACE_ROOTS`

## How Project Discovery Works

Candidate directories come from:

1. recent projects stored in `~/.local/state/codex-launch/recent_projects`
2. `PINNED_DIRS`
3. first-level child directories under `WORKSPACE_ROOTS`

Duplicates are removed while preserving order.

## How Session Discovery Works

- `codexs-picker` reads `~/.codex/state_5.sqlite`
- the launcher also includes a JSONL-based reader for `~/.codex/sessions`, `session_index.jsonl`, and `history.jsonl`

Both paths filter sessions by the selected project directory.

## Default Launch Behavior

When starting Codex, `codexs`:

- switches the process `cwd` to the selected project
- passes `-C <selected_dir>` to Codex
- adds `--yolo` by default
- disables default `--yolo` when `--sandbox` or `-s` is explicitly passed

This is intentional because interactive Codex commands such as `/resume` may consult the real process `cwd`.

## Development Checks

```bash
bash -n bin/codexs
bash -n codexs-install.sh
bash -n codexs-uninstall.sh
python3 -m py_compile libexec/codexs/codexs-picker
./codexs-install.sh --dry-run --verify --project-dir ~/foo-project-a --workspace-root ~/foo-workspace
./codexs-uninstall.sh --dry-run
```

## Notes

- `fzf` is treated as an external dependency and is strongly recommended for normal installation.
- The project is Linux-oriented and not tested on macOS or Windows.
- Bash completion is only provided for Bash.
- Workspace scanning is intentionally shallow.

## Disclaimer

This project's code was generated entirely with Codex and has not been fully tested end-to-end. If you plan to rely on it in your own environment, review it carefully and fork or adjust it as needed.
