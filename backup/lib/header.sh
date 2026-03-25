#!/usr/bin/env bash
# =============================================================================
# header.sh - Andrez.co Backup Suite shared header
# =============================================================================
# Source this file from backup.sh / restore.sh (after common.sh).
# Provides: print_header "backup" | "restore"
# =============================================================================

# Guard against multiple inclusions
[[ -n "${_HEADER_SH_LOADED:-}" ]] && return 0
_HEADER_SH_LOADED=1

# Additional colors not in common.sh
AMBER="\033[38;5;214m"
AMBER_DIM="\033[38;5;136m"
AMBER_DARK="\033[38;5;94m"
GREEN_DIM="\033[38;5;71m"
ORANGE="\033[38;5;208m"
DARK="\033[38;5;235m"

print_header() {
  local mode="${1:-}"   # "backup" | "restore"
  clear

  # ── ASCII art ────────────────────────────────
  echo -e "${AMBER}${BOLD}"
  echo -e "┏━┓┏┓╻╺┳┓┏━┓┏━╸╺━┓ ┏━╸┏━┓"
  echo -e "┣━┫┃┗┫ ┃┃┣┳┛┣╸ ┏━┛ ┃  ┃ ┃"
  echo -e "╹ ╹╹ ╹╺┻┛╹┗╸┗━╸┗━╸╹┗━╸┗━┛"
  echo -e "${RESET}"
  echo -e "  ${AMBER_DARK}BACKUP SUITE${RESET}  ${DARK}·  andrez.co${RESET}"
  echo ""

  # ── Command table ────────────────────────────
  # Col1 = 26 visible chars, Col2 = 38 visible chars (hardcoded to avoid ANSI width issues)
  echo -e "${DARK}  ┌──────────────────────────┬──────────────────────────────────────┐${RESET}"
  echo -e "${DARK}  │${RESET}  ${GRAY}COMMAND${RESET}                 ${DARK}│${RESET}  ${GRAY}DESCRIPTION${RESET}                         ${DARK}│${RESET}"
  echo -e "${DARK}  ├──────────────────────────┼──────────────────────────────────────┤${RESET}"

  if [[ "$mode" == "backup" ]]; then
    echo -e "${DARK}  │${RESET}  ${GREEN}${BOLD}backup.sh${RESET}  ${GREEN_DIM}◀ active${RESET}     ${DARK}│${RESET}  Create a new backup of your Mac     ${DARK}│${RESET}"
  else
    echo -e "${DARK}  │${RESET}  ${GRAY}backup.sh${RESET}               ${DARK}│${RESET}  ${DARK}Create a new backup of your Mac     ${RESET}${DARK}│${RESET}"
  fi

  echo -e "${DARK}  ├──────────────────────────┼──────────────────────────────────────┤${RESET}"

  if [[ "$mode" == "restore" ]]; then
    echo -e "${DARK}  │${RESET}  ${ORANGE}${BOLD}restore.sh${RESET}  ${ORANGE}◀ active${RESET}    ${DARK}│${RESET}  Restore your Mac from a backup      ${DARK}│${RESET}"
  else
    echo -e "${DARK}  │${RESET}  ${GRAY}restore.sh${RESET}              ${DARK}│${RESET}  ${DARK}Restore your Mac from a backup      ${RESET}${DARK}│${RESET}"
  fi

  echo -e "${DARK}  └──────────────────────────┴──────────────────────────────────────┘${RESET}"
  echo ""

  # ── Active command details ───────────────────
  case "$mode" in

    backup)
      echo -e "  ${GREEN}${BOLD}BACKUP${RESET}  ${DARK}─────────────────────────────────────────${RESET}"
      echo ""
      echo -e "${GRAY}  USAGE${RESET}"
      echo -e "  ${AMBER}\$${RESET} ${GREEN}./backup.sh${RESET} ${CYAN}<destination>${RESET} ${PURPLE}[--workspace]${RESET}"
      echo ""
      echo -e "${GRAY}  OPTIONS${RESET}"
      echo -e "  ${PURPLE}--workspace${RESET}           ${GRAY}Include ~/workspace projects${RESET}"
      echo -e "  ${GRAY}--help${RESET}                ${GRAY}Show this message${RESET}"
      echo ""
      echo -e "${GRAY}  EXAMPLES${RESET}"
      echo -e "  ${DARK}┃${RESET} ${AMBER}\$${RESET} ${GREEN}./backup.sh${RESET} ${CYAN}/Volumes/USB/mac-backup-$(date +%Y-%m-%d)/${RESET}"
      echo -e "  ${DARK}┃${RESET} ${GRAY}  # full backup to USB volume${RESET}"
      echo ""
      echo -e "  ${DARK}┃${RESET} ${AMBER}\$${RESET} ${GREEN}./backup.sh${RESET} ${CYAN}~/Desktop/${RESET} ${PURPLE}--workspace${RESET}"
      echo -e "  ${DARK}┃${RESET} ${GRAY}  # include ~/workspace projects${RESET}"
      ;;

    restore)
      echo -e "  ${ORANGE}${BOLD}RESTORE${RESET}  ${DARK}────────────────────────────────────────${RESET}"
      echo ""
      echo -e "${GRAY}  USAGE${RESET}"
      echo -e "  ${AMBER}\$${RESET} ${ORANGE}./restore.sh${RESET} ${CYAN}<backup_dir>${RESET} ${PURPLE}[--target <dir>]${RESET}"
      echo ""
      echo -e "${GRAY}  OPTIONS${RESET}"
      echo -e "  ${PURPLE}--target <dir>${RESET}        ${GRAY}Restore to alternative directory (safe testing)${RESET}"
      echo -e "  ${GRAY}--help${RESET}                ${GRAY}Show this message${RESET}"
      echo ""
      echo -e "${GRAY}  EXAMPLES${RESET}"
      echo -e "  ${DARK}┃${RESET} ${AMBER}\$${RESET} ${ORANGE}./restore.sh${RESET} ${CYAN}/Volumes/USB/mac-backup-2024-12-27/${RESET}"
      echo -e "  ${DARK}┃${RESET} ${GRAY}  # full restore from USB volume${RESET}"
      echo ""
      echo -e "  ${DARK}┃${RESET} ${AMBER}\$${RESET} ${ORANGE}./restore.sh${RESET} ${CYAN}/Volumes/USB/mac-backup-2024-12-27/${RESET} ${PURPLE}--target${RESET} ${CYAN}/tmp/test${RESET}"
      echo -e "  ${DARK}┃${RESET} ${GRAY}  # safe test restore to a temporary directory${RESET}"
      ;;

    *)
      echo -e "  ${GRAY}Run ${GREEN}./backup.sh --help${RESET}${GRAY} or ${ORANGE}./restore.sh --help${RESET}${GRAY} for usage.${RESET}"
      ;;
  esac

  echo ""
  echo -e "  ${DARK}──────────────────────────────────────────────────────${RESET}"
  echo -e "  ${AMBER_DARK}v1.0.0${RESET}  ${GREEN_DIM}macOS 14+${RESET}  ${DARK}MIT License · andrez.co${RESET}"
  echo ""
}
