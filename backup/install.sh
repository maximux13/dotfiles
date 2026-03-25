#!/usr/bin/env bash
# =============================================================================
# install.sh - Mac setup from scratch
# =============================================================================
# Run this on a new Mac with no dependencies:
#
#   curl -fsSL https://raw.githubusercontent.com/maximux13/dotfiles/main/install.sh | bash
#
# With a local backup folder:
#
#   curl -fsSL https://raw.githubusercontent.com/maximux13/dotfiles/main/install.sh | bash -s -- /Volumes/USB/mac-backup-2025/
#
# =============================================================================

set -euo pipefail

DOTFILES_REPO="https://github.com/maximux13/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="${1:-}"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD=$'\033[1m'
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
BG_CYAN=$'\033[46m'
FG_BLACK=$'\033[30m'
BG_PURPLE=$'\033[45m'
AMBER=$'\033[38;5;214m'

info()    { printf "   ${CYAN}→${RESET}  %s\n" "$*"; }
success() { printf "   ${GREEN}✓${RESET}  %s\n" "$*"; }
warn()    { printf "   ${YELLOW}!${RESET}  %s\n" "$*"; }
error()   { printf "   ${RED}✗${RESET}  %s\n" "$*" >&2; }
step() {
    echo ""
    printf "   ${BOLD}${CYAN}●${RESET}  ${BOLD}%s${RESET}\n" "$*"
    printf "   ${DIM}│${RESET}\n"
}

# Read from terminal even when stdin is a pipe (curl | bash)
read_tty() {
    local prompt="$1"
    local var_name="$2"
    printf "%s" "$prompt" > /dev/tty
    read -r "$var_name" < /dev/tty
}

# ── Intro ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${AMBER}"
echo -e "┏━┓┏┓╻╺┳┓┏━┓┏━╸╺━┓ ┏━╸┏━┓"
echo -e "┣━┫┃┗┫ ┃┃┣┳┛┣╸ ┏━┛ ┃  ┃ ┃"
echo -e "╹ ╹╹ ╹╺┻┛╹┗╸┗━╸┗━╸╹┗━╸┗━┛"
echo -e "${RESET}"
AMBER_DARK=$'\033[38;5;94m'
DARK=$'\033[38;5;235m'
echo -e "  ${AMBER_DARK}BACKUP SUITE${RESET}  ${DARK}·  andrez.co${RESET}"
echo ""
echo -e "  ${DIM}mac-install · dotfiles + restore${RESET}"
echo ""
echo -e "  ${BG_CYAN}${FG_BLACK} install ${RESET} ${DIM}Starting setup sequence...${RESET}"
echo ""

# ── Step 1: Xcode Command Line Tools ─────────────────────────────────────────
step "1/4  Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    success "Already installed"
else
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    printf "\n   ${YELLOW}?${RESET}  Press Enter once the installer finishes..." > /dev/tty
    read -r < /dev/tty
    success "Xcode Command Line Tools installed"
fi

# ── Step 2: Homebrew ──────────────────────────────────────────────────────────
step "2/4  Homebrew"

_setup_brew_path() {
    command -v brew &>/dev/null && return 0
    [[ -f "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)" && return 0
    [[ -f "/usr/local/bin/brew" ]]    && eval "$(/usr/local/bin/brew shellenv)"    && return 0
    return 1
}

_setup_brew_path

if command -v brew &>/dev/null; then
    success "Already installed ($(brew --version | head -1))"
else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    _setup_brew_path
    if command -v brew &>/dev/null; then
        success "Homebrew installed"
    else
        error "Homebrew installation failed"
        exit 1
    fi
fi

# ── Step 3: Clone dotfiles ────────────────────────────────────────────────────
step "3/4  Dotfiles"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    success "Already cloned at $DOTFILES_DIR"
elif [[ -d "$DOTFILES_DIR" ]]; then
    warn "~/.dotfiles exists but is not a git repo — skipping clone"
else
    info "Cloning $DOTFILES_REPO → $DOTFILES_DIR ..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    success "Cloned"
fi

# ── Step 4: Restore ───────────────────────────────────────────────────────────
step "4/4  Restore"

RESTORE_SCRIPT="$DOTFILES_DIR/backup/restore.sh"

if [[ ! -f "$RESTORE_SCRIPT" ]]; then
    error "restore.sh not found at $RESTORE_SCRIPT"
    exit 1
fi

chmod +x "$RESTORE_SCRIPT"

# If no backup dir was passed, ask interactively
if [[ -z "$BACKUP_DIR" ]]; then
    echo ""
    printf "   ${DIM}Do you have a backup folder to restore from?${RESET}\n"
    printf "   ${DIM}(leave empty to skip — only dotfiles will be set up)${RESET}\n"
    echo ""
    read_tty "   ${YELLOW}▸${RESET} Backup path: " BACKUP_DIR
fi

if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
    info "Launching restore from: $BACKUP_DIR"
    echo ""
    exec "$RESTORE_SCRIPT" "$BACKUP_DIR"
elif [[ -n "$BACKUP_DIR" ]]; then
    warn "Backup path not found: $BACKUP_DIR"
    warn "Skipping restore — run manually: ~/.dotfiles/backup/restore.sh <backup_dir>"
    exit 1
else
    info "No backup provided — skipping restore"
    echo ""
    printf "   ${BG_PURPLE}${FG_BLACK} next ${RESET} Run ${CYAN}stow${RESET} packages manually:\n"
    printf "   ${DIM}cd ~/.dotfiles && stow zsh git ghostty ...${RESET}\n"
    echo ""
    printf "   ${DIM}Or run restore later:${RESET}\n"
    printf "   ${CYAN}~/.dotfiles/backup/restore.sh /path/to/backup${RESET}\n"
    echo ""
fi
