#!/usr/bin/env bash
# =============================================================================
# workspace.sh - Workspace/Projects backup and restore functionality
# =============================================================================
# This script provides functions to backup and restore the workspace directory
# containing development projects, excluding build artifacts and dependencies.
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"

# Exclusions for development projects
WORKSPACE_EXCLUDES=(
    # Version control
    '.git'

    # Node.js / JavaScript
    'node_modules'
    '.npm'
    '.pnpm-store'
    '.yarn/cache'
    '.yarn/unplugged'

    # Build outputs
    'dist'
    'build'
    '.next'
    '.nuxt'
    '.output'
    '.turbo'
    '.parcel-cache'
    '.cache'
    '.webpack'

    # Python
    '.venv'
    'venv'
    '__pycache__'
    '*.pyc'
    '*.pyo'
    '.pytest_cache'
    '.mypy_cache'
    '.ruff_cache'
    '*.egg-info'

    # Rust
    'target'

    # Go
    'vendor'

    # Java / JVM
    '.gradle'
    '.m2'

    # IDE / Editor
    '.idea'

    # OS files
    '.DS_Store'
    'Thumbs.db'

    # Logs and temp
    '*.log'
    'logs'
    'tmp'
    '.temp'

    # Test coverage
    'coverage'
    '.nyc_output'
    'htmlcov'

    # Environment files with secrets (optional - uncomment if needed)
    # '.env'
    # '.env.local'
)

# backup_workspace - Create a compressed backup of the workspace directory
#
# Arguments:
#   $1 - backup_dir: Directory where the backup will be stored
#
# Creates: workspace.tar.gz in the backup directory
backup_workspace() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    if [[ ! -d "$WORKSPACE_DIR" ]]; then
        log_error "Workspace directory not found: $WORKSPACE_DIR"
        return 1
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    local backup_file="$backup_dir/workspace.tar.gz"

    # Get list of projects (directories only)
    local total
    total=$(find "$WORKSPACE_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

    log_info "Source: $WORKSPACE_DIR"
    log_dim "$total projects to backup"

    # Build exclude arguments
    local exclude_args=()
    for pattern in "${WORKSPACE_EXCLUDES[@]}"; do
        exclude_args+=("--exclude=$pattern")
    done

    local workspace_basename
    workspace_basename=$(basename "$WORKSPACE_DIR")

    # Start spinner with elapsed time and file size monitoring
    start_spinner "Compressing workspace..." true "$backup_file"

    # Run tar without verbose for speed
    local tar_result=0
    tar "${exclude_args[@]}" \
        -czf "$backup_file" \
        -C "$(dirname "$WORKSPACE_DIR")" \
        "$workspace_basename" 2>/dev/null || tar_result=$?

    stop_spinner

    # Clear line and restore cursor
    printf "\r\033[K"
    tput cnorm 2>/dev/null || true

    if [[ $tar_result -eq 0 && -f "$backup_file" ]]; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        log_success "Workspace backup created ($size)"
    else
        log_error "Failed to create workspace backup"
        return 1
    fi
}

# restore_workspace - Restore workspace from a backup
#
# Arguments:
#   $1 - backup_dir: Directory containing the backup
#   $2 - target_dir: (optional) Directory to restore to (default: $HOME)
#
# Extracts workspace.tar.gz to the target directory
restore_workspace() {
    local backup_dir="$1"
    local target_dir="${2:-$HOME}"
    local target_workspace="$target_dir/workspace"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    local backup_file="$backup_dir/workspace.tar.gz"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir"

    # Show backup file size
    local backup_size
    backup_size=$(du -h "$backup_file" | cut -f1)
    log_info "Backup size: $backup_size"

    # Backup existing workspace if present (only for real HOME)
    if [[ "$target_dir" == "$HOME" && -d "$WORKSPACE_DIR" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_existing="$WORKSPACE_DIR.backup.$timestamp"
        log_warn "Existing workspace found. Moving to $backup_existing"
        mv "$WORKSPACE_DIR" "$backup_existing"
    fi

    # Count projects in archive
    local total
    total=$(tar -tzf "$backup_file" 2>/dev/null | grep -E '^[^/]+/[^/]+/$' | cut -d'/' -f2 | sort -u | wc -l | tr -d ' ')
    log_dim "$total projects to restore"

    # Start spinner with elapsed time
    start_spinner "Extracting workspace..." true

    # Extract without verbose for speed
    local tar_result=0
    tar -xzf "$backup_file" -C "$target_dir" 2>/dev/null || tar_result=$?

    stop_spinner

    if [[ $tar_result -ne 0 || ! -d "$target_workspace" ]]; then
        log_error "Failed to restore workspace"
        return 1
    fi

    local size
    size=$(du -sh "$target_workspace" | cut -f1)
    log_success "Workspace extracted ($size)"

    # Show summary of restored projects
    local project_count
    project_count=$(find "$target_workspace" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    log_dim "$project_count projects restored"

    echo ""
    printf "   ${BG_YELLOW}${FG_BLACK} note ${RESET} ${DIM}Run 'npm install' or equivalent in each project${RESET}\n"
}
