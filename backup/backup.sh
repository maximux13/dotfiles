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
source "$LIB_DIR/crypto.sh"
source "$LIB_DIR/secrets.sh"
source "$LIB_DIR/dotfiles.sh"
source "$LIB_DIR/apps.sh"
source "$LIB_DIR/vscode.sh"
source "$LIB_DIR/npm.sh"

# Usage
usage() {
    echo ""
    printf "${BOLD}${CYAN}Mac Backup${RESET} - ${DIM}Secure backup for your Mac${RESET}\n"
    echo ""
    printf "${BOLD}Usage:${RESET}\n"
    printf "  %s ${CYAN}<destination>${RESET}\n" "$0"
    echo ""
    printf "${BOLD}Examples:${RESET}\n"
    printf "  %s /Volumes/USB/\n" "$0"
    printf "  %s ~/Desktop/\n" "$0"
    echo ""
    printf "${BOLD}What gets backed up:${RESET}\n"
    printf "  ${EMOJI_LOCK}  Secrets (SSH, AWS, GPG) ${DIM}[encrypted]${RESET}\n"
    printf "  ${EMOJI_FOLDER}  Dotfiles (~/.dotfiles)\n"
    printf "  ${EMOJI_BREW}  Homebrew packages\n"
    printf "  ${EMOJI_CODE}  VS Code Insiders\n"
    printf "  ${EMOJI_NPM}  NPM global packages\n"
    echo ""
    exit 1
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local dest="$1"

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
    print_intro "backup" "v1.0.0"

    # Show destination with tag
    tag_dest "$backup_dir"
    echo ""

    # ─────────────────────────────────────────
    # Secrets
    # ─────────────────────────────────────────
    print_tag "secrets" "orange" "${EMOJI_LOCK} Backing up secrets..."
    if backup_secrets "$backup_dir"; then
        tag_done "Secrets encrypted and saved"
    else
        tag_warn "Secrets backup skipped"
    fi

    # ─────────────────────────────────────────
    # Dotfiles
    # ─────────────────────────────────────────
    echo ""
    print_tag "dotfiles" "cyan" "${EMOJI_FOLDER} Backing up dotfiles..."
    if backup_dotfiles "$backup_dir"; then
        tag_done "Dotfiles archived"
    else
        tag_warn "Dotfiles backup failed"
    fi

    # ─────────────────────────────────────────
    # Homebrew
    # ─────────────────────────────────────────
    echo ""
    print_tag "brew" "yellow" "${EMOJI_BREW} Backing up Homebrew..."
    if backup_apps "$backup_dir"; then
        tag_done "Brewfile generated"
    else
        tag_warn "Homebrew backup failed"
    fi

    # ─────────────────────────────────────────
    # VS Code
    # ─────────────────────────────────────────
    echo ""
    print_tag "vscode" "blue" "${EMOJI_CODE} Backing up VS Code Insiders..."
    if backup_vscode "$backup_dir"; then
        tag_done "Extensions and settings saved"
    else
        tag_skip "VS Code backup skipped"
    fi

    # ─────────────────────────────────────────
    # NPM
    # ─────────────────────────────────────────
    echo ""
    print_tag "npm" "red" "${EMOJI_NPM} Backing up NPM packages..."
    if backup_npm "$backup_dir"; then
        tag_done "Global packages list saved"
    else
        tag_skip "NPM backup skipped"
    fi

    # ─────────────────────────────────────────
    # Manifest
    # ─────────────────────────────────────────
    echo ""
    print_tag "manifest" "purple" "${EMOJI_GEAR} Creating manifest..."
    create_manifest "$backup_dir"
    tag_done "Backup manifest created"

    # ─────────────────────────────────────────
    # Summary
    # ─────────────────────────────────────────
    echo ""
    printf "   ${GREEN}╭───────────────────────────────────────────╮${RESET}\n"
    printf "   ${GREEN}│${RESET}   ${BOLD}✓ Backup Complete!${RESET}                       ${GREEN}│${RESET}\n"
    printf "   ${GREEN}╰───────────────────────────────────────────╯${RESET}\n"
    echo ""

    # Show contents
    printf "   ${DIM}Contents:${RESET}\n"
    [[ -f "$backup_dir/secrets.tar.enc" ]] && printf "   ${DIM}├─${RESET} 🔐 secrets.tar.enc ${DIM}(encrypted)${RESET}\n"
    [[ -f "$backup_dir/dotfiles.tar.gz" ]] && printf "   ${DIM}├─${RESET} 📁 dotfiles.tar.gz\n"
    [[ -f "$backup_dir/Brewfile" ]] && printf "   ${DIM}├─${RESET} 🍺 Brewfile\n"
    [[ -d "$backup_dir/vscode-insiders" ]] && printf "   ${DIM}├─${RESET} 💻 vscode-insiders/\n"
    [[ -f "$backup_dir/npm-global.txt" ]] && printf "   ${DIM}├─${RESET} 📦 npm-global.txt\n"
    [[ -f "$backup_dir/manifest.json" ]] && printf "   ${DIM}╰─${RESET} ⚙️  manifest.json\n"

    echo ""
    printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} Copy this folder to your external drive\n"
    printf "   ${DIM}To restore:${RESET} ${CYAN}./restore.sh %s${RESET}\n" "$backup_dir"
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
        "vscode": $([ -d "$backup_dir/vscode-insiders" ] && echo "true" || echo "false"),
        "npm": $([ -f "$backup_dir/npm-global.txt" ] && echo "true" || echo "false")
    }
}
EOF
}

main "$@"
