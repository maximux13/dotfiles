#!/usr/bin/env bash
# =============================================================================
# vscode.sh - VS Code backup and restore functions (stable + insiders)
# =============================================================================
# Supports both VS Code stable ("code") and VS Code Insiders ("code-insiders").
# Whichever variant(s) are installed get backed up; whichever exist in the
# backup get restored.
# =============================================================================

set -euo pipefail

# shellcheck source=common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Map variant command → user-data directory
declare -A _VSCODE_DIR=(
    ["code"]="$HOME/Library/Application Support/Code/User"
    ["code-insiders"]="$HOME/Library/Application Support/Code - Insiders/User"
)

# Map variant command → backup subdirectory name
declare -A _VSCODE_BACKUP_SUBDIR=(
    ["code"]="vscode"
    ["code-insiders"]="vscode-insiders"
)

# Map variant command → human-readable label
declare -A _VSCODE_LABEL=(
    ["code"]="VS Code"
    ["code-insiders"]="VS Code Insiders"
)

# ---------------------------------------------------------------------------
# _backup_vscode_variant <backup_dir> <variant>
# ---------------------------------------------------------------------------
_backup_vscode_variant() {
    local backup_dir="$1"
    local variant="$2"
    local vscode_dir="${_VSCODE_DIR[$variant]}"
    local vscode_backup_dir="$backup_dir/${_VSCODE_BACKUP_SUBDIR[$variant]}"
    local label="${_VSCODE_LABEL[$variant]}"

    mkdir -p "$vscode_backup_dir"

    if command -v "$variant" &>/dev/null; then
        log_info "Exporting $label extensions..."
        "$variant" --list-extensions > "$vscode_backup_dir/extensions.txt"
    else
        log_warn "$variant command not found, skipping extensions"
    fi

    if [[ -f "$vscode_dir/settings.json" ]]; then
        log_info "Copying $label settings.json..."
        cp "$vscode_dir/settings.json" "$vscode_backup_dir/settings.json"
    else
        log_warn "$label settings.json not found"
    fi

    if [[ -f "$vscode_dir/keybindings.json" ]]; then
        log_info "Copying $label keybindings.json..."
        cp "$vscode_dir/keybindings.json" "$vscode_backup_dir/keybindings.json"
    else
        log_warn "$label keybindings.json not found"
    fi
}

# ---------------------------------------------------------------------------
# _restore_vscode_variant <backup_dir> <variant>
# ---------------------------------------------------------------------------
_restore_vscode_variant() {
    local backup_dir="$1"
    local variant="$2"
    local vscode_dir="${_VSCODE_DIR[$variant]}"
    local vscode_backup_dir="$backup_dir/${_VSCODE_BACKUP_SUBDIR[$variant]}"
    local label="${_VSCODE_LABEL[$variant]}"

    if ! command -v "$variant" &>/dev/null; then
        log_error "$variant command not found, cannot restore $label"
        return 1
    fi

    if [[ -f "$vscode_backup_dir/extensions.txt" ]]; then
        log_info "Installing $label extensions..."
        while IFS= read -r extension; do
            [[ -z "$extension" ]] && continue
            log_dim "Installing: $extension"
            "$variant" --install-extension "$extension" --force &>/dev/null
        done < "$vscode_backup_dir/extensions.txt"
    else
        log_warn "$label extensions.txt not found, skipping"
    fi

    mkdir -p "$vscode_dir"

    if [[ -f "$vscode_backup_dir/settings.json" ]]; then
        log_info "Restoring $label settings.json..."
        cp "$vscode_backup_dir/settings.json" "$vscode_dir/settings.json"
    else
        log_warn "$label settings.json backup not found"
    fi

    if [[ -f "$vscode_backup_dir/keybindings.json" ]]; then
        log_info "Restoring $label keybindings.json..."
        cp "$vscode_backup_dir/keybindings.json" "$vscode_dir/keybindings.json"
    else
        log_warn "$label keybindings.json backup not found"
    fi
}

# ---------------------------------------------------------------------------
# backup_vscode <backup_dir>
# Backs up every installed VS Code variant (stable and/or insiders).
# ---------------------------------------------------------------------------
backup_vscode() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        echo "Error: backup directory not specified" >&2
        return 1
    fi

    local backed_up=false
    for variant in code code-insiders; do
        local vscode_dir="${_VSCODE_DIR[$variant]}"
        if command -v "$variant" &>/dev/null || [[ -d "$vscode_dir" ]]; then
            _backup_vscode_variant "$backup_dir" "$variant"
            backed_up=true
        fi
    done

    if ! $backed_up; then
        log_warn "No VS Code installation found"
        return 1
    fi

    log_success "VS Code backup completed"
}

# ---------------------------------------------------------------------------
# restore_vscode <backup_dir>
# Restores every VS Code variant that has a subdirectory in the backup.
# ---------------------------------------------------------------------------
restore_vscode() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        echo "Error: backup directory not specified" >&2
        return 1
    fi

    local restored=false
    for variant in code code-insiders; do
        local vscode_backup_dir="$backup_dir/${_VSCODE_BACKUP_SUBDIR[$variant]}"
        if [[ -d "$vscode_backup_dir" ]]; then
            _restore_vscode_variant "$backup_dir" "$variant"
            restored=true
        fi
    done

    if ! $restored; then
        log_warn "No VS Code backup found"
        return 1
    fi

    log_success "VS Code restore completed"
}
