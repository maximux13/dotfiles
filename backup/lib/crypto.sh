#!/usr/bin/env bash
# =============================================================================
# crypto.sh - OpenSSL encryption utilities (works on fresh macOS)
# =============================================================================
# This script provides functions to encrypt and decrypt files using OpenSSL
# with AES-256-CBC and PBKDF2 key derivation.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Encrypt a file using AES-256-CBC with PBKDF2
# Usage: encrypt_file "input_file" "output_file"
encrypt_file() {
    local input_file="$1"
    local output_file="$2"

    if [[ ! -f "$input_file" ]]; then
        log_error "Input file does not exist: $input_file"
        return 1
    fi

    if ! require_command "openssl"; then
        return 1
    fi

    local passphrase passphrase_confirm

    printf "Enter passphrase for encryption: "
    read -rs passphrase
    printf "\n"

    if [[ -z "$passphrase" ]]; then
        log_error "Passphrase cannot be empty"
        return 1
    fi

    printf "Confirm passphrase: "
    read -rs passphrase_confirm
    printf "\n"

    if [[ "$passphrase" != "$passphrase_confirm" ]]; then
        log_error "Passphrases do not match"
        return 1
    fi

    if openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$input_file" \
        -out "$output_file" \
        -pass "pass:$passphrase" 2>/dev/null; then
        return 0
    else
        log_error "Encryption failed"
        [[ -f "$output_file" ]] && rm -f "$output_file"
        return 1
    fi
}

# Decrypt a file using AES-256-CBC with PBKDF2
# Usage: decrypt_file "input_file" "output_file"
decrypt_file() {
    local input_file="$1"
    local output_file="$2"

    if [[ ! -f "$input_file" ]]; then
        log_error "Input file does not exist: $input_file"
        return 1
    fi

    if ! require_command "openssl"; then
        return 1
    fi

    local passphrase

    printf "Enter passphrase for decryption: "
    read -rs passphrase
    printf "\n"

    if [[ -z "$passphrase" ]]; then
        log_error "Passphrase cannot be empty"
        return 1
    fi

    if openssl enc -aes-256-cbc -d -salt -pbkdf2 \
        -in "$input_file" \
        -out "$output_file" \
        -pass "pass:$passphrase" 2>/dev/null; then
        return 0
    else
        log_error "Decryption failed (wrong passphrase or corrupted file)"
        [[ -f "$output_file" ]] && rm -f "$output_file"
        return 1
    fi
}
