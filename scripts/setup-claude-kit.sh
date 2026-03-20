#!/usr/bin/env bash
# Setup claude-kit submodule and symlinks for Claude Code skills, agents, and hooks.
# Run after cloning the repo or when .claude/ symlinks are missing.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$ROOT/.claude"
KIT_DIR="$ROOT/.claude-kit"

# Init submodule if needed
if [ ! -f "$KIT_DIR/CLAUDE.md" ]; then
  echo "Initializing claude-kit submodule..."
  git -C "$ROOT" submodule update --init .claude-kit
fi

# Ensure .claude/ exists
mkdir -p "$CLAUDE_DIR"

# Create symlinks (replace existing files/dirs/links)
for target in skills agents hooks; do
  link="$CLAUDE_DIR/$target"
  if [ -L "$link" ]; then
    rm "$link"
  elif [ -e "$link" ]; then
    echo "Backing up existing $target to $target.bak"
    mv "$link" "$link.bak"
  fi
  ln -s "../.claude-kit/$target" "$link"
  echo "✓ .claude/$target → .claude-kit/$target"
done

echo "Done. Claude Code will now use skills, agents, and hooks from claude-kit."
