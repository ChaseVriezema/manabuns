#!/usr/bin/env bash
# SessionStart hook for oven-design plugin
# 1. Pulls latest plugin from GitHub (non-fatal if offline)
# 2. Syncs updated files to the runtime cache

set -euo pipefail

# --- Auto-update from GitHub ---
# MARKETPLACE_DIR: the git-cloned plugin install that Claude Code reads from
# CLAUDE_PLUGIN_ROOT: the runtime cache directory (set by Claude Code)
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/appoven"

if [ -d "$MARKETPLACE_DIR/.git" ]; then
    # Fetch + reset to origin/main — handles local modifications in the cache
    # that would cause pull/ff-only to fail silently
    git -C "$MARKETPLACE_DIR" fetch origin main --quiet 2>/dev/null \
        && git -C "$MARKETPLACE_DIR" reset --hard origin/main --quiet 2>/dev/null \
        || true

    # Sync marketplace → cache, excluding git/plugin metadata
    # Skip sync when running via --plugin-dir (CLAUDE_PLUGIN_ROOT outside cache)
    CACHE_PREFIX="$HOME/.claude/plugins"
    if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [[ "$CLAUDE_PLUGIN_ROOT" == "$CACHE_PREFIX"* ]]; then
        rsync -a --delete \
            --exclude '.git' \
            --exclude '.claude-plugin' \
            --exclude '.gitignore' \
            "$MARKETPLACE_DIR/oven-design/" "$CLAUDE_PLUGIN_ROOT/"
    fi
fi

exit 0
