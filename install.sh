#!/usr/bin/env bash
# Installs the Dev Team agents and /devteam command for Claude Code.
#
#   ./install.sh /path/to/project     # install into one project (recommended)
#   ./install.sh --global             # install for your user (every project)
#   add --force to overwrite existing files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/.claude"
FORCE=0
TARGET=""
GLOBAL=0

for arg in "$@"; do
  case "$arg" in
    --global) GLOBAL=1 ;;
    --force)  FORCE=1 ;;
    *)        TARGET="$arg" ;;
  esac
done

if [ "$GLOBAL" -eq 1 ]; then
  DEST="$HOME/.claude"
elif [ -n "$TARGET" ]; then
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/.claude"
else
  echo "Usage: ./install.sh <project-folder> | --global [--force]"
  exit 1
fi

for sub in agents commands security; do
  mkdir -p "$DEST/$sub"
  for f in "$SOURCE/$sub"/*.md; do
    d="$DEST/$sub/$(basename "$f")"
    if [ -e "$d" ] && [ "$FORCE" -eq 0 ]; then
      echo "skip   $d (exists; use --force to overwrite)"
    else
      cp "$f" "$d"
      echo "copied $d"
    fi
  done
done

# Security permission rules (deny reading secrets, git push, destructive commands, ...)
S="$DEST/settings.json"
if [ -e "$S" ] && [ "$FORCE" -eq 0 ]; then
  echo "skip   $S (exists; merge the 'permissions' block from this repo's .claude/settings.json by hand)"
else
  if [ -e "$S" ]; then cp "$S" "$S.bak"; echo "backup $S.bak"; fi
  cp "$SOURCE/settings.json" "$S"
  echo "copied $S"
fi

if [ "$GLOBAL" -eq 0 ]; then
  if [ ! -e "$TARGET/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
    echo "copied $TARGET/CLAUDE.md"
  else
    echo "skip   $TARGET/CLAUDE.md (exists; merge the 'Dev Team' section by hand)"
  fi
fi

echo
echo "Done. Restart Claude Code in the project and ask: 'Which subagents are available?'"
echo "Expect: senior-dev, junior-dev-1, junior-dev-2, security-reviewer, tester. Then try: /devteam <task>"
