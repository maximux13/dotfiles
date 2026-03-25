#!/usr/bin/env bash
# =============================================================================
# restore.sh - Mac Restore Script
# =============================================================================
# Interactive restore from a backup created by backup.sh. Supports restoring
# secrets, dotfiles, Homebrew packages, VS Code, and NPM packages.
# =============================================================================

set -euo pipefail

RESTORE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$RESTORE_SCRIPT_DIR/lib"

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

# Default restore target
RESTORE_TARGET="$HOME"
TEST_MODE=false

# Usage
usage() {
    print_header "restore"
    exit 1
}

# Build menu arrays based on what's available in the backup
_build_restore_menu() {
    local backup_dir="$1"

    MENU_ITEMS=("Homebrew + Apps" "Secrets (SSH, AWS, GPG)" "Dotfiles" "VS Code" "NPM Packages" "Workspace")
    MENU_ICONS=("${EMOJI_BREW}" "${EMOJI_LOCK}" "${EMOJI_FOLDER}" "${EMOJI_CODE}" "${EMOJI_NPM}" "${EMOJI_WORKSPACE}")
    MENU_AVAILABLE=(0 0 0 0 0 0)
    MENU_SELECTED=()

    [[ -f "$backup_dir/Brewfile" ]]                                               && MENU_AVAILABLE[0]=1
    [[ -f "$backup_dir/secrets.tar.enc" ]]                                        && MENU_AVAILABLE[1]=1
    [[ -f "$backup_dir/dotfiles.tar.gz" ]]                                        && MENU_AVAILABLE[2]=1
    { [[ -d "$backup_dir/vscode" ]] || [[ -d "$backup_dir/vscode-insiders" ]]; } && MENU_AVAILABLE[3]=1
    [[ -f "$backup_dir/npm-global.txt" ]]                                         && MENU_AVAILABLE[4]=1
    [[ -f "$backup_dir/workspace.tar.gz" ]]                                       && MENU_AVAILABLE[5]=1

    # Disable brew/vscode/npm in test mode
    if $TEST_MODE; then
        MENU_AVAILABLE[0]=0
        MENU_AVAILABLE[3]=0
        MENU_AVAILABLE[4]=0
    fi
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local backup_dir="$1"
    shift

    # Parse optional arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                if [[ -z "${2:-}" ]]; then
                    log_error "--target requires a directory path"
                    exit 1
                fi
                RESTORE_TARGET="$2"
                TEST_MODE=true
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate backup directory
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup directory does not exist: $backup_dir"
        exit 1
    fi

    # Show fancy intro based on mode
    if $TEST_MODE; then
        print_header "restore"
        tag_dest "$RESTORE_TARGET"
        mkdir -p "$RESTORE_TARGET"
    else
        print_header "restore"
    fi

    # Show backup info with tags
    if [[ -f "$backup_dir/manifest.json" ]]; then
        local hostname created
        hostname=$(grep -o '"hostname": "[^"]*"' "$backup_dir/manifest.json" | cut -d'"' -f4)
        created=$(grep -o '"created": "[^"]*"' "$backup_dir/manifest.json" | cut -d'"' -f4)
        print_tag "from" "cyan" "$hostname"
        print_tag "date" "purple" "$created"
        echo ""
    fi

    # Build and show interactive menu
    declare -a MENU_ITEMS MENU_ICONS MENU_AVAILABLE MENU_SELECTED
    _build_restore_menu "$backup_dir"

    echo ""
    if ! interactive_menu "What would you like to restore?" \
            MENU_ITEMS MENU_ICONS MENU_AVAILABLE MENU_SELECTED; then
        log_info "Restore cancelled"
        exit 0
    fi
    echo ""

    # Count selected items for step tracker
    local selected_count=0
    for s in "${MENU_SELECTED[@]}"; do (( selected_count += s )) || true; done
    steps_init "$selected_count"

    for i in "${!MENU_ITEMS[@]}"; do
        [[ "${MENU_SELECTED[$i]:-0}" -eq 0 ]] && continue

        case "$i" in
            0)  # Homebrew
                steps_next "${EMOJI_BREW} Homebrew + Apps"
                if restore_apps "$backup_dir"; then
                    steps_done "Packages restored"
                else
                    steps_done "Some packages failed" warn
                fi
                ;;
            1)  # Secrets
                steps_next "${EMOJI_LOCK} Secrets"
                if restore_secrets "$backup_dir" "$RESTORE_TARGET"; then
                    steps_done "Secrets restored"
                else
                    steps_done "Failed" fail
                fi
                ;;
            2)  # Dotfiles
                steps_next "${EMOJI_FOLDER} Dotfiles"
                if restore_dotfiles "$backup_dir" "$RESTORE_TARGET"; then
                    steps_done "Dotfiles restored"
                else
                    steps_done "Failed" fail
                fi
                ;;
            3)  # VS Code
                steps_next "${EMOJI_CODE} VS Code"
                if restore_vscode "$backup_dir"; then
                    steps_done "Extensions and settings restored"
                else
                    steps_done "Failed" fail
                fi
                ;;
            4)  # NPM
                steps_next "${EMOJI_NPM} NPM Packages"
                if restore_npm "$backup_dir"; then
                    steps_done "Global packages installed"
                else
                    steps_done "Failed" fail
                fi
                ;;
            5)  # Workspace
                steps_next "${EMOJI_WORKSPACE} Workspace"
                if restore_workspace "$backup_dir" "$RESTORE_TARGET"; then
                    steps_done "Projects restored"
                else
                    steps_done "Failed" fail
                fi
                ;;
        esac
    done

    # ─── Summary ──────────────────────────────────────────
    if $TEST_MODE; then
        print_complete "Restore Complete (test mode)" test
        printf "   ${BG_ORANGE}${FG_BLACK} test ${RESET} Restored to: ${CYAN}%s${RESET}\n" "$RESTORE_TARGET"
        printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} Verify contents, then run without --target\n"
    else
        print_complete "Restore Complete!" restore
        printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} You may need to restart your terminal\n"
    fi
    echo ""
}

main "$@"
