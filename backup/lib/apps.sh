#!/usr/bin/env bash
# =============================================================================
# apps.sh - Homebrew applications backup and restore functionality
# =============================================================================
# This script provides functions to backup and restore Homebrew formulae and
# casks using Brewfile.
# =============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Homebrew installation URL
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# backup_apps - Create a Brewfile backup of all installed Homebrew packages
#
# Arguments:
#   $1 - backup_dir: Directory where the Brewfile will be stored
#
# Creates: Brewfile in the backup directory
backup_apps() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    if ! command -v brew &>/dev/null; then
        log_error "Homebrew is not installed"
        return 1
    fi

    log_info "Backing up Homebrew packages..."

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    local brewfile="$backup_dir/Brewfile"

    # Dump all installed packages to Brewfile (suppress output)
    if ! brew bundle dump --file="$brewfile" --force &>/dev/null; then
        log_error "Failed to create Brewfile"
        return 1
    fi

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile was not created"
        return 1
    fi

    # Count formulae and casks
    local formulae_count casks_count tap_count mas_count
    formulae_count=$(grep -c '^brew "' "$brewfile" 2>/dev/null || true)
    casks_count=$(grep -c '^cask "' "$brewfile" 2>/dev/null || true)
    tap_count=$(grep -c '^tap "' "$brewfile" 2>/dev/null || true)
    mas_count=$(grep -c '^mas "' "$brewfile" 2>/dev/null || true)

    # Default to 0 if empty
    : "${formulae_count:=0}"
    : "${casks_count:=0}"
    : "${tap_count:=0}"
    : "${mas_count:=0}"

    log_success "Brewfile created"
    log_dim "Taps: $tap_count | Formulae: $formulae_count | Casks: $casks_count | MAS: $mas_count"
}

# restore_apps - Restore Homebrew packages from a Brewfile
#
# Arguments:
#   $1 - backup_dir: Directory containing the Brewfile
#
# Installs Homebrew if needed, then installs packages from Brewfile
restore_apps() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "Backup directory not specified"
        return 1
    fi

    local brewfile="$backup_dir/Brewfile"

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found: $brewfile"
        return 1
    fi

    # Check if Homebrew is installed, if not install it
    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew is not installed"
        _install_homebrew
    fi

    # Verify Homebrew is now available
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew installation failed or not in PATH"
        return 1
    fi

    log_info "Restoring Homebrew packages from $brewfile"

    # Show what will be installed
    local formulae_count casks_count
    formulae_count=$(grep -c '^brew "' "$brewfile" 2>/dev/null || echo "0")
    casks_count=$(grep -c '^cask "' "$brewfile" 2>/dev/null || echo "0")
    log_info "Installing $formulae_count formulae and $casks_count casks..."

    # Install packages from Brewfile
    # Using --no-lock to avoid Brewfile.lock.json creation
    # Some casks may fail (already installed, requires password, etc.)
    if brew bundle install --file="$brewfile" --no-lock; then
        log_success "All packages installed successfully"
    else
        log_warn "Some packages may have failed to install"
        log_info "This is normal - some casks require manual intervention"
        log_info "Run 'brew bundle check --file=$brewfile' to see what's missing"
    fi

    # Show any packages that failed
    log_info "Checking installation status..."
    if ! brew bundle check --file="$brewfile" 2>/dev/null; then
        log_warn "Some packages are not installed. Check the output above."
    else
        log_success "All packages from Brewfile are installed"
    fi
}

# _install_homebrew - Install Homebrew
#
# Installs Homebrew using the official installation script
_install_homebrew() {
    log_info "Installing Homebrew..."

    read -rp "Install Homebrew? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Skipping Homebrew installation"
        return 1
    fi

    # Download and run the Homebrew installer
    if /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"; then
        log_success "Homebrew installed successfully"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            log_info "Added Homebrew to PATH (Apple Silicon)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
            log_info "Added Homebrew to PATH (Intel)"
        fi
    else
        log_error "Failed to install Homebrew"
        return 1
    fi
}
