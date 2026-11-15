# Changelog

Changes in this port. The upstream commit the skill content matches is recorded in [`UPSTREAM`](UPSTREAM).

## Unreleased

- Synced the skill with upstream `620163e`: RTL/Arabic guide, story-server path traversal fix, snapshot input fixes, `agents/openai.yaml`, `examples/store.html`.
- `install.sh` and `install.ps1`: `--update`/`-Update`, `--uninstall`/`-Uninstall`, `--dry-run`/`-DryRun`. Old builds named `unslop` are only removed when they are clearly this port, never upstream's skill.
- Added `scripts/sync-upstream.sh`, `scripts/validate.mjs`, upstream's script tests (adapted to the new folder name), CI and a weekly upstream-sync workflow.

## Earlier

- Portable cross-agent build, renamed to `unslop-portable`, marked as an unofficial port.
