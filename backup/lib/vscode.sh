#!/usr/bin/env bash
# =============================================================================
# vscode.sh - VS Code Insiders backup and restore functions
# =============================================================================
# This script provides functions to backup and restore VS Code Insiders
# extensions and settings.
# =============================================================================

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

VSCODE_DIR="$HOME/Library/Application Support/Code - Insiders/User"

# Backup VS Code Insiders extensions and settings
# Arguments:
#   $1 - backup directory path
backup_vscode() {
    local backup_dir="$1"
    local vscode_backup_dir="$backup_dir/vscode-insiders"

    if [[ -z "$backup_dir" ]]; then
        echo "Error: backup directory not specified" >&2
        return 1
    fi

    mkdir -p "$vscode_backup_dir"

    # Export extensions list
    if command -v code-insiders &>/dev/null; then
        log_info "Exporting extensions list..."
        code-insiders --list-extensions > "$vscode_backup_dir/extensions.txt"
    else
        log_warn "code-insiders command not found, skipping extensions"
    fi

    # Copy settings.json if it exists
    if [[ -f "$VSCODE_DIR/settings.json" ]]; then
        log_info "Copying settings.json..."
        cp "$VSCODE_DIR/settings.json" "$vscode_backup_dir/settings.json"
    else
        log_warn "settings.json not found"
    fi

    # Copy keybindings.json if it exists
    if [[ -f "$VSCODE_DIR/keybindings.json" ]]; then
        log_info "Copying keybindings.json..."
        cp "$VSCODE_DIR/keybindings.json" "$vscode_backup_dir/keybindings.json"
    else
        log_warn "keybindings.json not found"
    fi

    log_success "VS Code Insiders backup completed"
}

# Restore VS Code Insiders extensions and settings
# Arguments:
#   $1 - backup directory path
restore_vscode() {
    local backup_dir="$1"
    local vscode_backup_dir="$backup_dir/vscode-insiders"

    if [[ -z "$backup_dir" ]]; then
        echo "Error: backup directory not specified" >&2
        return 1
    fi

    if ! command -v code-insiders &>/dev/null; then
        log_error "code-insiders command not found, cannot restore"
        return 1
    fi

    # Install extensions from list
    if [[ -f "$vscode_backup_dir/extensions.txt" ]]; then
        log_info "Installing extensions..."
        while IFS= read -r extension; do
            [[ -z "$extension" ]] && continue
            log_dim "Installing: $extension"
            code-insiders --install-extension "$extension" --force &>/dev/null
        done < "$vscode_backup_dir/extensions.txt"
    else
        log_warn "extensions.txt not found, skipping"
    fi

    # Ensure VS Code User directory exists
    mkdir -p "$VSCODE_DIR"

    # Restore settings.json
    if [[ -f "$vscode_backup_dir/settings.json" ]]; then
        log_info "Restoring settings.json..."
        cp "$vscode_backup_dir/settings.json" "$VSCODE_DIR/settings.json"
    else
        log_warn "settings.json backup not found"
    fi

    # Restore keybindings.json
    if [[ -f "$vscode_backup_dir/keybindings.json" ]]; then
        log_info "Restoring keybindings.json..."
        cp "$vscode_backup_dir/keybindings.json" "$VSCODE_DIR/keybindings.json"
    else
        log_warn "keybindings.json backup not found"
    fi

    log_success "VS Code Insiders restore completed"
}
