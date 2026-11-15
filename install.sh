#!/usr/bin/env bash
# Installs unslop-portable once and links it into each agent's skills folder.
# Usage: ./install.sh [--update] [--uninstall] [--dry-run] [--help]
set -euo pipefail

NAME="unslop-portable"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/$NAME"
CANONICAL="$HOME/.agents/skills/$NAME"
LINK_TARGETS=(
  "$HOME/.claude/skills/$NAME"
  "$HOME/.codex/skills/$NAME"
  "$HOME/.config/opencode/skills/$NAME"
)
# Antigravity does not follow symlinks, so it gets real copies.
COPY_TARGETS=(
  "$HOME/.gemini/config/skills/$NAME"
  "$HOME/.gemini/antigravity-cli/skills/$NAME"
)
# Folders of earlier builds of this port that were named "unslop".
LEGACY_DIRS=(
  "$HOME/.agents/skills/unslop"
  "$HOME/.claude/skills/unslop"
  "$HOME/.codex/skills/unslop"
  "$HOME/.config/opencode/skills/unslop"
  "$HOME/.gemini/config/skills/unslop"
  "$HOME/.gemini/antigravity-cli/skills/unslop"
)

MODE=install
DRY=0
for arg in "$@"; do
  case "$arg" in
    --update) MODE=update ;;
    --uninstall) MODE=uninstall ;;
    --dry-run) DRY=1 ;;
    -h|--help)
      sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'
      echo "  (default)    install, skipping anything that already exists"
      echo "  --update     refresh the installed copy and the Antigravity copies"
      echo "  --uninstall  remove the installed copy, links and copies"
      echo "  --dry-run    print what would happen without changing anything"
      exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

run() {
  if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi
}

# A legacy folder is only removed when it is clearly this port, never upstream unslop.
is_port_legacy() {
  local dir="$1"
  [ -L "$dir" ] && return 0
  [ -f "$dir/SKILL.md" ] && grep -qi "unofficial port" "$dir/SKILL.md"
}

clean_legacy() {
  for dir in "${LEGACY_DIRS[@]}"; do
    { [ -e "$dir" ] || [ -L "$dir" ]; } || continue
    if is_port_legacy "$dir"; then
      run rm -rf "$dir"
      echo "Removed old build of this port: $dir"
    else
      echo "Left alone (looks like upstream unslop, not this port): $dir"
    fi
  done
}

uninstall() {
  for target in "${LINK_TARGETS[@]}" "${COPY_TARGETS[@]}" "$CANONICAL"; do
    if [ -e "$target" ] || [ -L "$target" ]; then
      run rm -rf "$target"
      echo "Removed $target"
    fi
  done
  clean_legacy
}

if [ "$MODE" = uninstall ]; then
  uninstall
  exit 0
fi

if [ ! -d "$SOURCE" ]; then
  echo "skills/$NAME not found next to this script."
  exit 1
fi

clean_legacy

if [ -e "$CANONICAL" ] && [ "$MODE" = update ]; then
  run rm -rf "$CANONICAL"
fi
if [ -e "$CANONICAL" ]; then
  echo "Skill already installed at $CANONICAL (leaving it as is; use --update to refresh)."
else
  run mkdir -p "$(dirname "$CANONICAL")"
  run cp -R "$SOURCE" "$CANONICAL"
  echo "Copied skill to $CANONICAL"
fi

for target in "${LINK_TARGETS[@]}"; do
  run mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Exists, skipped: $target"
    continue
  fi
  run ln -s "$CANONICAL" "$target"
  echo "Linked $target -> $CANONICAL"
done

for target in "${COPY_TARGETS[@]}"; do
  run mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$MODE" = update ]; then
      run rm -rf "$target"
    else
      echo "Exists, skipped: $target (run with --update to refresh this copy)"
      continue
    fi
  fi
  run cp -R "$SOURCE" "$target"
  echo "Copied $target (Antigravity does not follow symlinks)"
done
