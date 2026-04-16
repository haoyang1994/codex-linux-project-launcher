# INSTALL

This document is written for Codex or another terminal agent that is helping a user install `codexs`.

## Goal

Install `codexs` for a user in a Linux terminal environment, configure initial project paths, and verify the result.

## Required Agent Behavior

Before running the installer, the agent should:

1. Inspect the repository layout.
2. Check whether these dependencies are available:
   - `bash`
   - `python3`
   - `codex`
   - `fzf`
   - optionally `whiptail`
3. Ask the user for:
   - one or more initial project directories to pin
   - one or more workspace root directories
   - whether `DEFAULT_YOLO` should stay enabled by default
   - whether an existing `~/.config/codex-launch/config` should be preserved or overwritten
4. If required dependencies are missing, explain what is missing and offer to install or guide the user.

## Default Dependency Policy

When helping a user install `codexs`, the agent should treat `fzf` as a default dependency to install when it is missing, unless the user explicitly says not to install extra packages.

Recommended policy:

- `bash`, `python3`, and `codex` are required
- `fzf` should be installed by default if missing
- `whiptail` is optional and only needed as a secondary fallback

If package installation is needed, the agent should first detect the platform package manager and then ask before making system changes.

## Recommended Installation Flow

1. Review current config state:

```bash
ls -l ~/.config/codex-launch/config ~/.config/codex-launch/config.example 2>/dev/null || true
```

2. Run a dry-run first:

```bash
./codexs-install.sh --dry-run --verify \
  --project-dir ~/foo-project-a \
  --workspace-root ~/foo-workspace
```

3. Run the real install:

```bash
./codexs-install.sh --verify \
  --project-dir ~/foo-project-a \
  --workspace-root ~/foo-workspace
```

4. If the user wants to replace an existing config:

```bash
./codexs-install.sh --verify --force-config \
  --project-dir ~/foo-project-a \
  --workspace-root ~/foo-workspace
```

5. Validate the result:

```bash
codexs --help
codexs repo list
```

## Notes About DEFAULT_YOLO

The installer does not directly toggle `DEFAULT_YOLO`.

If the user wants it disabled by default, the agent should either:

- edit `~/.config/codex-launch/config` after installation and set `DEFAULT_YOLO=0`
- or explain how to change it manually

## Notes About Dependencies

- `codex` is required for actual launcher usage.
- `fzf` should be installed by default for the best picker experience.
- `whiptail` is optional.
- If both `fzf` and `whiptail` are missing, `codexs` still works with plain terminal selection.

Suggested install preference for `fzf`:

1. Use the system package manager when available.
2. If that is not possible and the user approves, use another user-level installation method appropriate for the machine.
3. If installation is blocked, explain that `codexs` will still work with degraded picker behavior.

## Uninstall

Preview:

```bash
./codexs-uninstall.sh --dry-run
```

Remove launcher files:

```bash
./codexs-uninstall.sh
```

Remove launcher files and config:

```bash
./codexs-uninstall.sh --purge-config
```
