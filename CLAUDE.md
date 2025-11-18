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
- `--clean-cache` - Clean package manager and Docker caches (npm, pnpm, yarn, Docker)
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
- **Cache cleanup**: Function `clean_caches()` handles npm, pnpm, yarn, and Docker cache cleanup
  - Detects available tools with `command -v`
  - Respects dry-run mode for cache estimation
  - Uses appropriate commands: `npm cache clean --force`, `pnpm store prune`, `yarn cache clean`, `docker system prune -af --volumes`
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
