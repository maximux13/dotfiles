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
    echo ""
    printf "${BOLD}${CYAN}Mac Restore${RESET} - ${DIM}Restore your Mac from backup${RESET}\n"
    echo ""
    printf "${BOLD}Usage:${RESET}\n"
    printf "  %s ${CYAN}<backup_dir>${RESET} [options]\n" "$0"
    echo ""
    printf "${BOLD}Options:${RESET}\n"
    printf "  ${CYAN}--target <dir>${RESET}  Restore to alternative directory ${DIM}(safe testing)${RESET}\n"
    echo ""
    printf "${BOLD}Examples:${RESET}\n"
    printf "  %s /Volumes/USB/mac-backup-2024-12-27/\n" "$0"
    printf "  %s /Volumes/USB/mac-backup-2024-12-27/ --target /tmp/test\n" "$0"
    echo ""
    exit 1
}

# Show menu and get selection
show_menu() {
    local backup_dir="$1"

    # Check what's available
    local has_secrets=false
    local has_dotfiles=false
    local has_brewfile=false
    local has_vscode=false
    local has_npm=false
    local has_workspace=false

    [[ -f "$backup_dir/secrets.tar.enc" ]] && has_secrets=true
    [[ -f "$backup_dir/dotfiles.tar.gz" ]] && has_dotfiles=true
    [[ -f "$backup_dir/Brewfile" ]] && has_brewfile=true
    [[ -d "$backup_dir/vscode-insiders" ]] && has_vscode=true
    [[ -f "$backup_dir/npm-global.txt" ]] && has_npm=true
    [[ -f "$backup_dir/workspace.tar.gz" ]] && has_workspace=true

    printf "   ${BG_CYAN}${FG_BLACK} select ${RESET} ${BOLD}What would you like to restore?${RESET}\n"
    echo ""

    # Homebrew
    if $TEST_MODE; then
        printf "   ${DIM}○${RESET} ${DIM}[1]${RESET} ${EMOJI_BREW}  ${DIM}Homebrew + Apps (skip in test)${RESET}\n"
    elif $has_brewfile; then
        printf "   ${GREEN}●${RESET} ${BOLD}[1]${RESET} ${EMOJI_BREW}  Homebrew + Apps\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[1]${RESET} ${EMOJI_BREW}  ${DIM}Homebrew + Apps (not in backup)${RESET}\n"
    fi

    # Secrets
    if $has_secrets; then
        printf "   ${GREEN}●${RESET} ${BOLD}[2]${RESET} ${EMOJI_LOCK}  Secrets (SSH, AWS, GPG)\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[2]${RESET} ${EMOJI_LOCK}  ${DIM}Secrets (not in backup)${RESET}\n"
    fi

    # Dotfiles
    if $has_dotfiles; then
        printf "   ${GREEN}●${RESET} ${BOLD}[3]${RESET} ${EMOJI_FOLDER}  Dotfiles (stow packages)\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[3]${RESET} ${EMOJI_FOLDER}  ${DIM}Dotfiles (not in backup)${RESET}\n"
    fi

    # VS Code
    if $TEST_MODE; then
        printf "   ${DIM}○${RESET} ${DIM}[4]${RESET} ${EMOJI_CODE}  ${DIM}VS Code Insiders (skip in test)${RESET}\n"
    elif $has_vscode; then
        printf "   ${GREEN}●${RESET} ${BOLD}[4]${RESET} ${EMOJI_CODE}  VS Code Insiders\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[4]${RESET} ${EMOJI_CODE}  ${DIM}VS Code Insiders (not in backup)${RESET}\n"
    fi

    # NPM
    if $TEST_MODE; then
        printf "   ${DIM}○${RESET} ${DIM}[5]${RESET} ${EMOJI_NPM}  ${DIM}NPM Global Packages (skip in test)${RESET}\n"
    elif $has_npm; then
        printf "   ${GREEN}●${RESET} ${BOLD}[5]${RESET} ${EMOJI_NPM}  NPM Global Packages\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[5]${RESET} ${EMOJI_NPM}  ${DIM}NPM Packages (not in backup)${RESET}\n"
    fi

    # Workspace
    if $has_workspace; then
        printf "   ${GREEN}●${RESET} ${BOLD}[6]${RESET} ${EMOJI_WORKSPACE} Workspace (projects)\n"
    else
        printf "   ${DIM}○${RESET} ${DIM}[6]${RESET} ${EMOJI_WORKSPACE} ${DIM}Workspace (not in backup)${RESET}\n"
    fi

    echo ""
    printf "   ${DIM}───────────────────────────────────────────────${RESET}\n"
    echo ""
    if $TEST_MODE; then
        printf "   ${PURPLE}[a]${RESET} All testable ${DIM}(2,3,6)${RESET}   ${RED}[q]${RESET} Quit\n"
    else
        printf "   ${PURPLE}[a]${RESET} All available          ${RED}[q]${RESET} Quit\n"
    fi
    echo ""
    printf "   ${YELLOW}▸${RESET} Enter selection ${DIM}(comma-separated):${RESET} "
}

# Bootstrap: ensure minimum requirements
bootstrap() {
    print_section "System Check" "$EMOJI_GEAR"

    # Check for Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        log_warn "Xcode Command Line Tools not installed"
        log_step "Installing Xcode Command Line Tools..."
        xcode-select --install
        printf "${YELLOW}?${RESET} Press Enter after installation completes..."
        read -r
    fi
    log_success "Xcode Command Line Tools"

    # Check for Homebrew
    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not installed"
        if confirm "Install Homebrew now?"; then
            log_step "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    fi

    if command -v brew &>/dev/null; then
        log_success "Homebrew"
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
        print_intro_test "v1.0.0"
        tag_dest "$RESTORE_TARGET"
        mkdir -p "$RESTORE_TARGET"
    else
        print_intro "restore" "v1.0.0"
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

    # Bootstrap system (skip in test mode)
    if ! $TEST_MODE; then
        bootstrap
    fi

    # Show menu
    show_menu "$backup_dir"
    read -r selection

    # Handle quit
    if [[ "$selection" == "q" ]]; then
        log_info "Restore cancelled"
        exit 0
    fi

    # Handle "all"
    if [[ "$selection" == "a" ]]; then
        if $TEST_MODE; then
            selection="2,3,6"
        else
            selection="1,2,3,4,5,6"
        fi
    fi

    # Parse selection
    IFS=',' read -ra choices <<< "$selection"
    echo ""

    for choice in "${choices[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')

        case "$choice" in
            1)
                if $TEST_MODE; then
                    tag_skip "Homebrew (test mode)"
                elif [[ -f "$backup_dir/Brewfile" ]]; then
                    print_tag "brew" "yellow" "${EMOJI_BREW} Restoring Homebrew..."
                    if restore_apps "$backup_dir"; then
                        tag_done "Homebrew packages restored"
                    else
                        tag_error "Homebrew restore failed"
                    fi
                else
                    tag_warn "Brewfile not found in backup"
                fi
                ;;
            2)
                if [[ -f "$backup_dir/secrets.tar.enc" ]]; then
                    print_tag "secrets" "orange" "${EMOJI_LOCK} Restoring secrets..."
                    if restore_secrets "$backup_dir" "$RESTORE_TARGET"; then
                        tag_done "Secrets restored"
                    else
                        tag_error "Secrets restore failed"
                    fi
                else
                    tag_warn "Secrets not found in backup"
                fi
                ;;
            3)
                if [[ -f "$backup_dir/dotfiles.tar.gz" ]]; then
                    print_tag "dotfiles" "cyan" "${EMOJI_FOLDER} Restoring dotfiles..."
                    if restore_dotfiles "$backup_dir" "$RESTORE_TARGET"; then
                        tag_done "Dotfiles restored"
                    else
                        tag_error "Dotfiles restore failed"
                    fi
                else
                    tag_warn "Dotfiles not found in backup"
                fi
                ;;
            4)
                if $TEST_MODE; then
                    tag_skip "VS Code (test mode)"
                elif [[ -d "$backup_dir/vscode-insiders" ]]; then
                    print_tag "vscode" "blue" "${EMOJI_CODE} Restoring VS Code Insiders..."
                    if restore_vscode "$backup_dir"; then
                        tag_done "VS Code Insiders restored"
                    else
                        tag_error "VS Code restore failed"
                    fi
                else
                    tag_warn "VS Code backup not found"
                fi
                ;;
            5)
                if $TEST_MODE; then
                    tag_skip "NPM (test mode)"
                elif [[ -f "$backup_dir/npm-global.txt" ]]; then
                    print_tag "npm" "red" "${EMOJI_NPM} Restoring NPM packages..."
                    if restore_npm "$backup_dir"; then
                        tag_done "NPM packages restored"
                    else
                        tag_error "NPM restore failed"
                    fi
                else
                    tag_warn "NPM packages not found"
                fi
                ;;
            6)
                if [[ -f "$backup_dir/workspace.tar.gz" ]]; then
                    print_tag "workspace" "pink" "${EMOJI_WORKSPACE}Restoring workspace..."
                    if restore_workspace "$backup_dir" "$RESTORE_TARGET"; then
                        tag_done "Workspace restored"
                    else
                        tag_error "Workspace restore failed"
                    fi
                else
                    tag_warn "Workspace not found in backup"
                fi
                ;;
            *)
                tag_warn "Invalid option: $choice"
                ;;
        esac
        echo ""
    done

    # Success message
    echo ""
    printf "   ${GREEN}╭───────────────────────────────────────────╮${RESET}\n"
    printf "   ${GREEN}│${RESET}   ${BOLD}✓ Restore Complete!${RESET}                      ${GREEN}│${RESET}\n"
    printf "   ${GREEN}╰───────────────────────────────────────────╯${RESET}\n"
    echo ""

    if $TEST_MODE; then
        printf "   ${BG_ORANGE}${FG_BLACK} test ${RESET} Restored to: ${CYAN}%s${RESET}\n" "$RESTORE_TARGET"
        printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} Verify contents, then run without --target\n"
    else
        printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} You may need to restart your terminal\n"
    fi
    echo ""
}

main "$@"
