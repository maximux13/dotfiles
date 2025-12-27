#!/usr/bin/env bash
# =============================================================================
# common.sh - Shared utilities for Mac backup system
# =============================================================================
# This script provides common functions, color codes, logging utilities,
# and UI elements used across various backup and restore scripts.
# =============================================================================

# Guard against multiple inclusions
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0
_COMMON_SH_LOADED=1

# =============================================================================
# Colors (256-color support)
# =============================================================================
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# Vibrant colors (foreground)
RED='\033[38;5;203m'
GREEN='\033[38;5;114m'
YELLOW='\033[38;5;221m'
BLUE='\033[38;5;111m'
PURPLE='\033[38;5;183m'
CYAN='\033[38;5;116m'
ORANGE='\033[38;5;215m'
PINK='\033[38;5;218m'
GRAY='\033[38;5;245m'
WHITE='\033[38;5;255m'
MAGENTA='\033[38;5;207m'

# Background colors for tags
BG_GREEN='\033[48;5;114m'
BG_RED='\033[48;5;203m'
BG_BLUE='\033[48;5;111m'
BG_PURPLE='\033[48;5;183m'
BG_CYAN='\033[48;5;116m'
BG_ORANGE='\033[48;5;215m'
BG_PINK='\033[48;5;218m'
BG_YELLOW='\033[48;5;221m'
BG_GRAY='\033[48;5;240m'
BG_BLACK='\033[48;5;236m'

# Dark foreground for tags
FG_BLACK='\033[38;5;236m'

# =============================================================================
# Emojis
# =============================================================================
EMOJI_INFO="💡"
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_WARN="⚠️ "
EMOJI_ROCKET="🚀"
EMOJI_PACKAGE="📦"
EMOJI_LOCK="🔐"
EMOJI_FOLDER="📁"
EMOJI_BREW="🍺"
EMOJI_CODE="💻"
EMOJI_NPM="📦"
EMOJI_CHECK="✓"
EMOJI_ARROW="→"
EMOJI_SPARKLES="✨"
EMOJI_GEAR="⚙️ "
EMOJI_CLOCK="⏱️ "
EMOJI_SHIELD="🛡️ "
EMOJI_BACKUP="💾"
EMOJI_RESTORE="♻️ "
EMOJI_MAC="🍎"

# =============================================================================
# Intro Headers - Clean modern design
# =============================================================================
print_intro() {
    local mode="${1:-backup}"  # backup or restore
    local version="${2:-v1.0.0}"

    clear
    echo ""

    if [[ "$mode" == "backup" ]]; then
        printf "   ${PURPLE}╭───────────────────────────────────────────╮${RESET}\n"
        printf "   ${PURPLE}│${RESET}                                           ${PURPLE}│${RESET}\n"
        printf "   ${PURPLE}│${RESET}   ${BOLD}💾 Mac Backup${RESET}                           ${PURPLE}│${RESET}\n"
        printf "   ${PURPLE}│${RESET}   ${DIM}Secure backup for your Mac${RESET}              ${PURPLE}│${RESET}\n"
        printf "   ${PURPLE}│${RESET}                                           ${PURPLE}│${RESET}\n"
        printf "   ${PURPLE}╰───────────────────────────────────────────╯${RESET}\n"
        echo ""
        printf "   ${BG_PURPLE}${FG_BLACK} backup ${RESET} ${PURPLE}$version${RESET} ${DIM}Starting backup sequence...${RESET}\n"
    else
        printf "   ${GREEN}╭───────────────────────────────────────────╮${RESET}\n"
        printf "   ${GREEN}│${RESET}                                           ${GREEN}│${RESET}\n"
        printf "   ${GREEN}│${RESET}   ${BOLD}♻️  Mac Restore${RESET}                          ${GREEN}│${RESET}\n"
        printf "   ${GREEN}│${RESET}   ${DIM}Restore from backup${RESET}                      ${GREEN}│${RESET}\n"
        printf "   ${GREEN}│${RESET}                                           ${GREEN}│${RESET}\n"
        printf "   ${GREEN}╰───────────────────────────────────────────╯${RESET}\n"
        echo ""
        printf "   ${BG_GREEN}${FG_BLACK} restore ${RESET} ${GREEN}$version${RESET} ${DIM}Starting restore sequence...${RESET}\n"
    fi
    echo ""
}

# Print intro for test mode
print_intro_test() {
    local version="${1:-v1.0.0}"

    clear
    echo ""

    printf "   ${ORANGE}╭───────────────────────────────────────────╮${RESET}\n"
    printf "   ${ORANGE}│${RESET}                                           ${ORANGE}│${RESET}\n"
    printf "   ${ORANGE}│${RESET}   ${BOLD}🧪 Test Mode${RESET}                             ${ORANGE}│${RESET}\n"
    printf "   ${ORANGE}│${RESET}   ${DIM}Safe testing - files will NOT change${RESET}    ${ORANGE}│${RESET}\n"
    printf "   ${ORANGE}│${RESET}                                           ${ORANGE}│${RESET}\n"
    printf "   ${ORANGE}╰───────────────────────────────────────────╯${RESET}\n"
    echo ""
    printf "   ${BG_ORANGE}${FG_BLACK} test ${RESET} ${ORANGE}$version${RESET} ${DIM}Running in sandbox mode...${RESET}\n"
    echo ""
}

# =============================================================================
# Tags (Astro-style labels)
# =============================================================================
# Usage: print_tag "label" "color" "message"
# Colors: green, purple, cyan, orange, pink, yellow, blue, red, gray
print_tag() {
    local label="$1"
    local color="$2"
    local message="${3:-}"

    local bg_color fg_color text_color
    case "$color" in
        green)   bg_color="$BG_GREEN"; text_color="$GREEN" ;;
        purple)  bg_color="$BG_PURPLE"; text_color="$PURPLE" ;;
        cyan)    bg_color="$BG_CYAN"; text_color="$CYAN" ;;
        orange)  bg_color="$BG_ORANGE"; text_color="$ORANGE" ;;
        pink)    bg_color="$BG_PINK"; text_color="$PINK" ;;
        yellow)  bg_color="$BG_YELLOW"; text_color="$YELLOW" ;;
        blue)    bg_color="$BG_BLUE"; text_color="$BLUE" ;;
        red)     bg_color="$BG_RED"; text_color="$RED" ;;
        gray)    bg_color="$BG_GRAY"; text_color="$GRAY" ;;
        *)       bg_color="$BG_PURPLE"; text_color="$PURPLE" ;;
    esac

    printf "   ${bg_color}${FG_BLACK} %s ${RESET}" "$label"
    if [[ -n "$message" ]]; then
        printf " %s" "$message"
    fi
    printf "\n"
}

# Predefined tags for common operations
tag_dest() { printf "   ${BG_CYAN}${FG_BLACK} dest ${RESET} %s\n" "$1"; }
tag_info() { printf "   ${BG_BLUE}${FG_BLACK} info ${RESET} %s\n" "$1"; }
tag_step() { printf "   ${BG_PURPLE}${FG_BLACK} step ${RESET} %s\n" "$1"; }
tag_done() { printf "   ${BG_GREEN}${FG_BLACK} done ${RESET} ${GREEN}✓${RESET} %s\n" "$1"; }
tag_warn() { printf "   ${BG_YELLOW}${FG_BLACK} warn ${RESET} ${YELLOW}%s${RESET}\n" "$1"; }
tag_error() { printf "   ${BG_RED}${FG_BLACK} fail ${RESET} ${RED}%s${RESET}\n" "$1"; }
tag_skip() { printf "   ${BG_GRAY}${FG_BLACK} skip ${RESET} ${DIM}%s${RESET}\n" "$1"; }

# =============================================================================
# Spinner
# =============================================================================
SPINNER_PID=""
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# Start a spinner with a message
# Usage: start_spinner "Loading..."
start_spinner() {
    local message="${1:-Loading...}"

    # Don't start if not in a terminal
    [[ ! -t 1 ]] && return

    (
        local i=0
        while true; do
            printf "\r${CYAN}${SPINNER_FRAMES[$i]}${RESET} ${DIM}%s${RESET}" "$message"
            i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
            sleep 0.08
        done
    ) &
    SPINNER_PID=$!
    disown
}

# Stop the spinner
# Usage: stop_spinner [success|error|warn]
stop_spinner() {
    local status="${1:-success}"

    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
    fi

    # Clear the line
    printf "\r\033[K"
}

# Run a command with a spinner
# Usage: with_spinner "message" command args...
with_spinner() {
    local message="$1"
    shift

    start_spinner "$message"

    if "$@" >/dev/null 2>&1; then
        stop_spinner
        log_success "$message"
        return 0
    else
        stop_spinner
        log_error "$message failed"
        return 1
    fi
}

# =============================================================================
# Logging Functions (all aligned with 3-space indent)
# =============================================================================

log_info() {
    printf "   ${DIM}→${RESET} %s\n" "$1"
}

log_success() {
    printf "   ${GREEN}✓${RESET} %s\n" "$1"
}

log_error() {
    printf "   ${RED}✗${RESET} %s\n" "$1" >&2
}

log_warn() {
    printf "   ${YELLOW}!${RESET} %s\n" "$1"
}

# Styled log for steps
log_step() {
    printf "   ${PURPLE}→${RESET} %s\n" "$1"
}

# Dimmed log for secondary info
log_dim() {
    printf "   ${DIM}  %s${RESET}\n" "$1"
}

# =============================================================================
# Banners and UI
# =============================================================================

# Print a fancy banner
# Usage: print_banner "Title" [emoji]
print_banner() {
    local title="$1"
    local emoji="${2:-$EMOJI_ROCKET}"
    local width=45
    local padding=$(( (width - ${#title} - 4) / 2 ))

    echo ""
    printf "${PURPLE}╭"
    printf '─%.0s' $(seq 1 $width)
    printf "╮${RESET}\n"

    printf "${PURPLE}│${RESET}"
    printf "%*s" $padding ""
    printf " %s ${BOLD}%s${RESET} " "$emoji" "$title"
    printf "%*s" $((padding - 1)) ""
    printf "${PURPLE}│${RESET}\n"

    printf "${PURPLE}╰"
    printf '─%.0s' $(seq 1 $width)
    printf "╯${RESET}\n"
    echo ""
}

# Print a section header
# Usage: print_section "Section Name" emoji
print_section() {
    local name="$1"
    local emoji="${2:-📌}"
    echo ""
    printf "${BOLD}${CYAN}%s %s${RESET}\n" "$emoji" "$name"
    printf "${DIM}%s${RESET}\n" "─────────────────────────────────"
}

# Print a completion box
# Usage: print_complete "Message"
print_complete() {
    local message="$1"
    echo ""
    printf "${GREEN}╭─────────────────────────────────────────────╮${RESET}\n"
    printf "${GREEN}│${RESET}  ${EMOJI_SPARKLES} ${BOLD}%s${RESET}%*s${GREEN}│${RESET}\n" "$message" $((40 - ${#message})) ""
    printf "${GREEN}╰─────────────────────────────────────────────╯${RESET}\n"
    echo ""
}

# Progress bar (for future use)
# Usage: progress_bar current total
progress_bar() {
    local current=$1
    local total=$2
    local width=30
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r${CYAN}["
    printf "${GREEN}%${filled}s" | tr ' ' '█'
    printf "${DIM}%${empty}s" | tr ' ' '░'
    printf "${CYAN}]${RESET} ${BOLD}%3d%%${RESET}" "$percent"
}

# =============================================================================
# Menu helpers
# =============================================================================

# Print a menu option
# Usage: print_option "1" "Description" [disabled]
print_option() {
    local key="$1"
    local desc="$2"
    local disabled="${3:-false}"

    if [[ "$disabled" == "true" ]]; then
        printf "  ${DIM}[%s] %s${RESET}\n" "$key" "$desc"
    else
        printf "  ${CYAN}[${BOLD}%s${RESET}${CYAN}]${RESET} %s\n" "$key" "$desc"
    fi
}

# =============================================================================
# Utility Functions
# =============================================================================

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

get_timestamp() {
    date +"%Y-%m-%d_%H%M%S"
}

confirm() {
    local prompt="${1:-Are you sure?}"
    local response

    printf "${YELLOW}?${RESET} %s ${DIM}[y/N]:${RESET} " "$prompt"
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Animated typing effect (for fun intros)
type_text() {
    local text="$1"
    local delay="${2:-0.02}"

    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

# Format file size
format_size() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}
