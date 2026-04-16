# Publishing Notes

## Suggested GitHub Description

- A project-aware launcher for the OpenAI Codex CLI with scoped session resume, picker UI, and installable Linux-style tooling.

## Suggested Topics

- `codex`
- `openai`
- `cli`
- `terminal`
- `bash`
- `python`
- `developer-tools`
- `productivity`

## Publish Checklist

- Confirm placeholder example paths are still generic
- Confirm no machine-specific absolute paths remain in tracked files
- Confirm `fzf` is documented as an external optional dependency
- Confirm `LICENSE` is present and correct
- Re-run the local checks below

## Recommended Checks

```bash
bash -n bin/codexs
bash -n codexs-install.sh
bash -n codexs-uninstall.sh
python3 -m py_compile libexec/codexs/codexs-picker
./codexs-install.sh --dry-run --verify --project-dir ~/foo-project-a --workspace-root ~/foo-workspace
./codexs-uninstall.sh --dry-run
```

## License

This repository uses Apache 2.0.
