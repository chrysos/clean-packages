# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains `clean-packages.sh`, a bash script for automated cleanup of first-level `node_modules` and `vendor` dependency directories in projects within `/Code`, with additional support for cleaning package manager and Docker caches.

**Key Behavior:**
- Removes only first-level dependency directories (e.g., `/Code/project/node_modules`)
- Preserves nested dependency directories (e.g., `/Code/project/subfolder/node_modules`)
- Preserves internal package dependencies (e.g., `/Code/project/node_modules/.pnpm/pkg/node_modules`)

## Script Usage

### Basic Commands

**Dry-run (safe preview):**
```bash
./clean-packages.sh
# or explicitly
./clean-packages.sh --dry-run
```

**Execute with confirmation:**
```bash
./clean-packages.sh --execute
```

**Execute without confirmation (dangerous):**
```bash
./clean-packages.sh --execute --force
```

**Custom directory:**
```bash
./clean-packages.sh --dir /other/path --dry-run
```

**Clean caches (npm, pnpm, yarn, Docker):**
```bash
./clean-packages.sh --clean-cache
```

**Full cleanup (dependencies + caches):**
```bash
./clean-packages.sh --execute --clean-cache
```

### Available Options

- `--dry-run` - Preview mode (default), shows what would be deleted
- `--execute` - Actually performs deletion
- `--force` - Skips confirmation prompt (use with caution)
- `--dir <path>` - Specify target directory (default: `~/Code`)
- `--clean-cache` - Clean package manager, tooling, AI, browser, Electron, and Docker caches (npm, pnpm, yarn, Go, Composer, pip, Serena, Xcode, Gradle, uv, Cypress, Playwright, Homebrew, Codex/Claude/ChatGPT, browsers, Electron apps, Docker)
- `--help` or `-h` - Display help

## Architecture

The script operates in four main phases:

1. **Discovery Phase**: Uses `find` with `-maxdepth 2` to locate first-level `node_modules` and `vendor` directories
2. **Analysis Phase**: Calculates sizes and presents summary to user
3. **Cache Cleanup Phase**: (when `--clean-cache` is used) Cleans package manager and Docker caches
4. **Execution Phase**: (when `--execute` is used) Removes directories and generates log file

### Important Implementation Details

- **Default mode is dry-run** for safety
- **Depth control**: `find -maxdepth 2` ensures only project-level dependencies are found
- **Cache cleanup**: Function `clean_caches()` handles npm, pnpm, yarn, Go, Composer, pip, Serena, and Docker cache cleanup
  - Detects available tools with `command -v`
  - Respects dry-run mode for cache estimation
  - Uses appropriate commands: `npm cache clean --force`, `pnpm store prune`, `yarn cache clean`, `go clean -cache`, `composer clear-cache`, `pip cache purge`, `docker system prune -af --volumes`
  - **Serena**: not a CLI tool — removes per-project `<project>/.serena/cache` directories under the target dir (found via `find -maxdepth 3 -path "*/.serena/cache"`) plus global `~/.serena/logs`. Preserves `memories/`, `project.yml`, and `~/.serena/language_servers` (the downloaded LSP binaries are expensive to re-download)
  - **Directory-based caches** use the `clean_dir_cache <label> <dir> <log_key>` helper (estimates in dry-run, `rm -rf` in execute; relies on bash dynamic scoping to update `total_freed`/`cache_log`). Used for: Xcode `DerivedData` + `iOS DeviceSupport`, Gradle `~/.gradle/caches`, `~/.cache/uv`, Cypress, Playwright
  - **Xcode** also runs `xcrun simctl delete unavailable` to drop orphaned simulators (guarded by `command -v xcrun`)
  - **Homebrew**: `brew cleanup -s` + removes `brew --cache`; dry-run parses `brew cleanup -n` for the estimate
  - **AI tool caches** (Codex, Claude, ChatGPT): only HTTP/runtime caches under `~/Library/Caches/*` + `~/.cache/codex-runtimes`. NEVER touches sessions, history, `~/.claude/projects` (memories), `~/.codex/worktrees` (may hold uncommitted work), plugins, or VM bundles
  - **Browser caches**: named `~/Library/Caches/*` dirs (Chrome/Google, Brave, Firefox, Edge, Arc). Only HTTP cache — browser profiles/history (under `Application Support`) are untouched
  - **Electron app sweep**: generic `find -maxdepth 2` over `~/Library/Application Support/*/{Cache,Code Cache,GPUCache,Service Worker,DawnWebGPUCache}` — catches Slack, Cursor, Deezer, Claude Desktop, etc. automatically. Only removes regenerable cache subdirs, never the apps' data. Close the apps before cleaning to avoid glitches
  - **Orphaned app data** (leftover `Application Support` dirs from uninstalled apps) is NOT handled by the script — it's app data, not cache, and is a one-time manual cleanup
- **Logging**: Execution mode creates timestamped log files (format: `cleanup-log-YYYY-MM-DD-HH-MM-SS.txt`)
- **Colorized output**: Uses ANSI color codes for terminal display
- **Size calculation**: Uses `du -sk` for accurate directory size reporting

### Security Features

- Defaults to safe dry-run mode
- Requires explicit confirmation unless `--force` is used
- Directory validation before execution
- Error handling with success/failure tracking

## Modifying the Script

When modifying `clean-packages.sh`:
- Maintain the dry-run default behavior for safety
- Preserve the `-maxdepth 2` constraint to prevent removing nested dependencies
- Keep the confirmation prompt mechanism intact
- If adding new cache cleanup tools, add detection logic in `clean_caches()` function
- Ensure new cache cleanup respects dry-run mode for safe preview
- Update both README.md and CLAUDE.md if changing behavior or adding options
- Test with `--dry-run` before testing `--execute` mode
- When adding cache cleanup for new tools, follow the pattern:
  1. Check tool availability with `command -v`
  2. Handle dry-run mode separately
  3. Show appropriate status messages
  4. Log operations for execution mode
