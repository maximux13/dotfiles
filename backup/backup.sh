#!/usr/bin/env bash
# =============================================================================
# backup.sh - Mac Backup Script
# =============================================================================
# Creates a complete backup for migrating to a new Mac or reformatting.
# Backs up secrets (encrypted), dotfiles, Homebrew packages, VS Code, and NPM.
# =============================================================================

set -euo pipefail

BACKUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BACKUP_SCRIPT_DIR/lib"

# Source libraries
source "$LIB_DIR/common.sh"
source "$LIB_DIR/header.sh"
source "$LIB_DIR/crypto.sh"
source "$LIB_DIR/secrets.sh"
source "$LIB_DIR/dotfiles.sh"
source "$LIB_DIR/apps.sh"
source "$LIB_DIR/vscode.sh"
source "$LIB_DIR/npm.sh"
source "$LIB_DIR/workspace.sh"

# Flags
INCLUDE_WORKSPACE=false

# Usage
usage() {
    print_header "backup"
    exit 1
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local dest="$1"
    shift

    # Parse optional arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workspace)
                INCLUDE_WORKSPACE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate destination
    if [[ ! -d "$dest" ]]; then
        log_error "Destination does not exist: $dest"
        exit 1
    fi

    # Create timestamped backup directory
    local timestamp
    timestamp=$(get_timestamp)
    local backup_dir="$dest/mac-backup-$timestamp"

    mkdir -p "$backup_dir"

    # Show fancy intro
    print_header "backup"

    # Show destination with tag
    tag_dest "$backup_dir"
    echo ""

    # Count steps (manifest is always last)
    local total_steps=6
    $INCLUDE_WORKSPACE && total_steps=7
    steps_init $total_steps

    # ─── Secrets ──────────────────────────────────────────
    steps_next "${EMOJI_LOCK} Secrets"
    if backup_secrets "$backup_dir"; then
        steps_done "Encrypted and saved"
    else
        steps_done "Skipped" warn
    fi

    # ─── Dotfiles ─────────────────────────────────────────
    steps_next "${EMOJI_FOLDER} Dotfiles"
    if backup_dotfiles "$backup_dir"; then
        steps_done "Archived"
    else
        steps_done "Failed" fail
    fi

    # ─── Homebrew ─────────────────────────────────────────
    steps_next "${EMOJI_BREW} Homebrew"
    if backup_apps "$backup_dir"; then
        steps_done "Brewfile generated"
    else
        steps_done "Failed" fail
    fi

    # ─── VS Code ──────────────────────────────────────────
    steps_next "${EMOJI_CODE} VS Code"
    if backup_vscode "$backup_dir"; then
        steps_done "Extensions and settings saved"
    else
        steps_done "Skipped" skip
    fi

    # ─── NPM ──────────────────────────────────────────────
    steps_next "${EMOJI_NPM} NPM"
    if backup_npm "$backup_dir"; then
        steps_done "Global packages list saved"
    else
        steps_done "Skipped" skip
    fi

    # ─── Workspace (optional) ─────────────────────────────
    if $INCLUDE_WORKSPACE; then
        steps_next "${EMOJI_WORKSPACE} Workspace"
        if backup_workspace "$backup_dir"; then
            steps_done "Archived (excluding node_modules)"
        else
            steps_done "Failed" fail
        fi
    fi

    # ─── Manifest ─────────────────────────────────────────
    steps_next "${EMOJI_GEAR} Manifest"
    create_manifest "$backup_dir"
    steps_done "manifest.json created"

    # ─── Summary ──────────────────────────────────────────
    print_complete "Backup Complete!" backup

    local tree_items=()
    [[ -f "$backup_dir/secrets.tar.enc" ]]  && tree_items+=("${EMOJI_LOCK} secrets.tar.enc ${DIM}(encrypted)${RESET}")
    [[ -f "$backup_dir/dotfiles.tar.gz" ]]  && tree_items+=("${EMOJI_FOLDER} dotfiles.tar.gz")
    [[ -f "$backup_dir/Brewfile" ]]         && tree_items+=("${EMOJI_BREW} Brewfile")
    [[ -d "$backup_dir/vscode" ]]           && tree_items+=("${EMOJI_CODE} vscode/")
    [[ -d "$backup_dir/vscode-insiders" ]]  && tree_items+=("${EMOJI_CODE} vscode-insiders/")
    [[ -f "$backup_dir/npm-global.txt" ]]   && tree_items+=("${EMOJI_NPM} npm-global.txt")
    [[ -f "$backup_dir/workspace.tar.gz" ]] && tree_items+=("${EMOJI_WORKSPACE} workspace.tar.gz")
    [[ -f "$backup_dir/manifest.json" ]]    && tree_items+=("${EMOJI_GEAR} manifest.json")

    print_file_tree "${tree_items[@]}"

    echo ""
    printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} Copy this folder to your external drive\n"
    printf "   ${DIM}On a new Mac, run:${RESET} ${CYAN}./install.sh${RESET} ${DIM}from inside the backup folder${RESET}\n"
    echo ""
}

create_manifest() {
    local backup_dir="$1"
    local manifest="$backup_dir/manifest.json"

    cat > "$manifest" << EOF
{
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "hostname": "$(hostname)",
    "macos_version": "$(sw_vers -productVersion)",
    "user": "$USER",
    "contents": {
        "secrets": $([ -f "$backup_dir/secrets.tar.enc" ] && echo "true" || echo "false"),
        "dotfiles": $([ -f "$backup_dir/dotfiles.tar.gz" ] && echo "true" || echo "false"),
        "brewfile": $([ -f "$backup_dir/Brewfile" ] && echo "true" || echo "false"),
        "vscode": $(([[ -d "$backup_dir/vscode" ]] || [[ -d "$backup_dir/vscode-insiders" ]]) && echo "true" || echo "false"),
        "npm": $([ -f "$backup_dir/npm-global.txt" ] && echo "true" || echo "false"),
        "workspace": $([ -f "$backup_dir/workspace.tar.gz" ] && echo "true" || echo "false")
    }
}
EOF
}

main "$@"
