#!/usr/bin/env bash
# =============================================================================
# secrets.sh - Secrets backup and restore functions for Mac backup system
# =============================================================================
# This script provides functions to backup and restore sensitive files and
# directories using tar and OpenSSL encryption.
# =============================================================================

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$(dirname "$SCRIPT_DIR")"

# Source dependencies
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/crypto.sh"

# Configuration
SECRETS_ARCHIVE_NAME="secrets.tar"
SECRETS_ENCRYPTED_NAME="secrets.tar.enc"

# =============================================================================
# backup_secrets - Backup sensitive files and directories
# =============================================================================
# Arguments:
#   $1 - backup_dir: Directory where encrypted backup will be stored
#
# Description:
#   Sources paths.conf to get list of paths to backup, creates a tar archive
#   of all existing paths, encrypts the archive, and removes the unencrypted
#   version.
# =============================================================================
backup_secrets() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        log_error "backup_secrets: backup directory not specified"
        return 1
    fi

    # Ensure backup directory exists
    mkdir -p "$backup_dir"

    # Source paths configuration
    local paths_conf="${BACKUP_ROOT}/config/paths.conf"
    if [[ ! -f "$paths_conf" ]]; then
        log_error "Paths configuration not found: $paths_conf"
        return 1
    fi
    source "$paths_conf"

    # Collect existing paths
    local paths_to_backup=()
    local skipped_paths=()

    for path in "${SECRETS_PATHS[@]}"; do
        # Expand tilde to home directory
        local expanded_path="${path/#\~/$HOME}"

        if [[ -e "$expanded_path" ]]; then
            paths_to_backup+=("$expanded_path")
        else
            skipped_paths+=("$path")
        fi
    done

    # Check if we have anything to backup
    if [[ ${#paths_to_backup[@]} -eq 0 ]]; then
        log_error "No secrets paths found to backup"
        return 1
    fi

    # Log skipped paths
    if [[ ${#skipped_paths[@]} -gt 0 ]]; then
        log_info "Skipping non-existent paths:"
        for path in "${skipped_paths[@]}"; do
            log_info "  - $path"
        done
    fi

    # Create tar archive
    local tar_path="${backup_dir}/${SECRETS_ARCHIVE_NAME}"
    local encrypted_path="${backup_dir}/${SECRETS_ENCRYPTED_NAME}"

    log_info "Creating secrets archive..."

    # Use tar with paths relative to home directory for proper extraction
    if ! tar -cvf "$tar_path" -C "$HOME" \
        "${paths_to_backup[@]/#$HOME\//}" 2>/dev/null; then
        log_error "Failed to create secrets archive"
        return 1
    fi

    # Encrypt the archive
    log_info "Encrypting secrets archive..."
    if ! encrypt_file "$tar_path" "$encrypted_path"; then
        log_error "Failed to encrypt secrets archive"
        rm -f "$tar_path"
        return 1
    fi

    # Remove unencrypted archive
    rm -f "$tar_path"

    # Log what was backed up
    log_success "Secrets backup complete!"
    log_info "Backed up paths:"
    for path in "${paths_to_backup[@]}"; do
        log_info "  - ${path/#$HOME/~}"
    done
    log_info "Encrypted archive: $encrypted_path"

    return 0
}

# =============================================================================
# restore_secrets - Restore sensitive files and directories
# =============================================================================
# Arguments:
#   $1 - backup_dir: Directory containing the encrypted backup
#   $2 - target_dir: (optional) Directory to restore to (default: $HOME)
#
# Description:
#   Decrypts the secrets archive, extracts files to target directory, sets
#   appropriate permissions on sensitive directories, and removes the
#   decrypted archive.
# =============================================================================
restore_secrets() {
    local backup_dir="$1"
    local target_dir="${2:-$HOME}"

    if [[ -z "$backup_dir" ]]; then
        log_error "restore_secrets: backup directory not specified"
        return 1
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir"

    local encrypted_path="${backup_dir}/${SECRETS_ENCRYPTED_NAME}"
    local tar_path="${backup_dir}/${SECRETS_ARCHIVE_NAME}"

    # Check if encrypted archive exists
    if [[ ! -f "$encrypted_path" ]]; then
        log_error "Encrypted secrets archive not found: $encrypted_path"
        return 1
    fi

    # Decrypt the archive
    log_info "Decrypting secrets archive..."
    if ! decrypt_file "$encrypted_path" "$tar_path"; then
        log_error "Failed to decrypt secrets archive"
        return 1
    fi

    # Extract to target directory
    log_info "Extracting secrets to $target_dir ..."
    if ! tar -xvf "$tar_path" -C "$target_dir" 2>/dev/null; then
        log_error "Failed to extract secrets archive"
        rm -f "$tar_path"
        return 1
    fi

    # Remove decrypted archive
    rm -f "$tar_path"

    # Set correct permissions on sensitive directories
    log_info "Setting secure permissions..."

    # SSH directory - 700 for directory, 600 for private keys
    if [[ -d "$target_dir/.ssh" ]]; then
        chmod 700 "$target_dir/.ssh"
        find "$target_dir/.ssh" -type f ! -name "*.pub" ! -name "known_hosts" ! -name "config" \
            -exec chmod 600 {} \; 2>/dev/null || true
        log_info "  - Set .ssh permissions to 700"
    fi

    # GnuPG directory - 700 for directory
    if [[ -d "$target_dir/.gnupg" ]]; then
        chmod 700 "$target_dir/.gnupg"
        chmod -R go-rwx "$target_dir/.gnupg" 2>/dev/null || true
        log_info "  - Set .gnupg permissions to 700"
    fi

    # AWS directory - 700 for directory, 600 for credentials
    if [[ -d "$target_dir/.aws" ]]; then
        chmod 700 "$target_dir/.aws"
        [[ -f "$target_dir/.aws/credentials" ]] && chmod 600 "$target_dir/.aws/credentials"
        log_info "  - Set .aws permissions to 700"
    fi

    # Individual sensitive files - 600
    for file in "$target_dir/.netrc" "$target_dir/.npmrc"; do
        if [[ -f "$file" ]]; then
            chmod 600 "$file"
            log_info "  - Set $(basename "$file") permissions to 600"
        fi
    done

    log_success "Secrets restore complete!"

    return 0
}
