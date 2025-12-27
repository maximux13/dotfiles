#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh - Dotfiles backup and restore functionality
# =============================================================================
# This script provides functions to backup and restore dotfiles managed with
# GNU Stow.
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"

# backup_dotfiles - Create a compressed backup of the dotfiles directory
#
# Arguments:
#   $1 - backup_dir: Directory where the backup will be stored
#
# Creates: dotfiles.tar.gz in the backup directory
backup_dotfiles() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi

    log_info "Backing up dotfiles from $DOTFILES_DIR"

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    local backup_file="$backup_dir/dotfiles.tar.gz"

    # Create tarball excluding .git directory to save space
    tar --exclude='.git' \
        -czf "$backup_file" \
        -C "$(dirname "$DOTFILES_DIR")" \
        "$(basename "$DOTFILES_DIR")"

    if [[ -f "$backup_file" ]]; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        log_success "Dotfiles backup created: $backup_file ($size)"
    else
        log_error "Failed to create dotfiles backup"
        return 1
    fi
}

# restore_dotfiles - Restore dotfiles from a backup and optionally stow packages
#
# Arguments:
#   $1 - backup_dir: Directory containing the backup
#   $2 - target_dir: (optional) Directory to restore to (default: $HOME)
#
# Extracts dotfiles.tar.gz and offers to stow packages
restore_dotfiles() {
    local backup_dir="$1"
    local target_dir="${2:-$HOME}"
    local target_dotfiles="$target_dir/.dotfiles"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    local backup_file="$backup_dir/dotfiles.tar.gz"

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir"

    log_info "Restoring dotfiles from $backup_file"

    # Backup existing dotfiles if present (only for real HOME)
    if [[ "$target_dir" == "$HOME" && -d "$DOTFILES_DIR" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_existing="$DOTFILES_DIR.backup.$timestamp"
        log_warn "Existing dotfiles found. Moving to $backup_existing"
        mv "$DOTFILES_DIR" "$backup_existing"
    fi

    # Extract the backup
    tar -xzf "$backup_file" -C "$target_dir"

    if [[ ! -d "$target_dotfiles" ]]; then
        log_error "Failed to restore dotfiles"
        return 1
    fi

    log_success "Dotfiles extracted to $target_dotfiles"

    # List available stow packages (subdirectories without dot prefix)
    local packages=()
    while IFS= read -r -d '' dir; do
        local name
        name=$(basename "$dir")
        # Skip hidden directories
        if [[ ! "$name" =~ ^\. ]]; then
            packages+=("$name")
        fi
    done < <(find "$target_dotfiles" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No stow packages found"
        return 0
    fi

    log_info "Available stow packages: ${packages[*]}"

    # Skip stow in test mode
    if [[ "$target_dir" != "$HOME" ]]; then
        log_info "Skipping stow in test mode"
        return 0
    fi

    # Ask user which packages to stow
    echo ""
    read -rp "Stow packages? (a)ll, (s)elect, (n)one: " choice

    case "$choice" in
        a|A|all)
            log_info "Stowing all packages..."
            for pkg in "${packages[@]}"; do
                _stow_package "$pkg"
            done
            ;;
        s|S|select)
            read -rp "Enter package numbers separated by spaces (e.g., 1 3 5): " selections
            for sel in $selections; do
                local idx=$((sel - 1))
                if [[ $idx -ge 0 && $idx -lt ${#packages[@]} ]]; then
                    _stow_package "${packages[$idx]}"
                else
                    log_warn "Invalid selection: $sel"
                fi
            done
            ;;
        n|N|none)
            log_info "Skipping stow. Run 'stow <package>' manually from $DOTFILES_DIR"
            ;;
        *)
            log_warn "Invalid choice. Skipping stow."
            ;;
    esac

    log_success "Dotfiles restore complete"
}

# _stow_package - Helper function to stow a single package
#
# Arguments:
#   $1 - package: Name of the stow package
_stow_package() {
    local package="$1"

    if ! command -v stow &>/dev/null; then
        log_error "GNU Stow is not installed. Please install it first."
        return 1
    fi

    log_info "Stowing package: $package"

    if stow -d "$DOTFILES_DIR" -t "$HOME" "$package" 2>&1; then
        log_success "Stowed: $package"
    else
        log_error "Failed to stow: $package"
    fi
}
