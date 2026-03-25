#!/usr/bin/env bash
# =============================================================================
# npm.sh - NPM global packages backup and restore functions
# =============================================================================
# This script provides functions to backup and restore globally installed
# NPM packages.
# =============================================================================

set -euo pipefail

# shellcheck source=common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Backup globally installed NPM packages
# Arguments:
#   $1 - backup directory path
backup_npm() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "backup directory not specified"
        return 1
    fi

    if ! command -v npm &>/dev/null; then
        log_error "npm command not found"
        return 1
    fi

    mkdir -p "$backup_dir"

    log_info "Exporting global packages..."

    # Get global packages as JSON and parse package names (excluding npm itself)
    npm list -g --depth=0 --json 2>/dev/null | \
        grep -E '^\s+"[^"]+":' | \
        sed 's/.*"\([^"]*\)".*/\1/' | \
        grep -v '^npm$' > "$backup_dir/npm-global.txt"

    log_success "NPM packages list saved"
}

# Restore globally installed NPM packages
# Arguments:
#   $1 - backup directory path
restore_npm() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "backup directory not specified"
        return 1
    fi

    if ! command -v npm &>/dev/null; then
        log_error "npm command not found, cannot restore"
        return 1
    fi

    if [[ ! -f "$backup_dir/npm-global.txt" ]]; then
        log_error "npm-global.txt not found"
        return 1
    fi

    log_info "Installing global packages..."
    while IFS= read -r package; do
        [[ -z "$package" ]] && continue
        log_dim "Installing: $package"
        npm install -g "$package" &>/dev/null
    done < "$backup_dir/npm-global.txt"

    log_success "NPM packages restored"
}
