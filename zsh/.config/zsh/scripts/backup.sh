#!/bin/bash

echo "
🔒 Configuration Backup Tool 🔒
================================
"

backup_dir="$HOME/config_backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

backup_items=(
    # SSH 🔑
    "$HOME/.ssh/id_rsa"
    "$HOME/.ssh/id_rsa.pub"
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/id_ed25519.pub"
    "$HOME/.ssh/config"
    "$HOME/.ssh/known_hosts"

    # Git 📦
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"

    # Shell 🐚
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"

    # VPN 🔐
    "$HOME/.vpn"

    # AWS ☁️
    "$HOME/.aws/config"
    "$HOME/.aws/credentials"

    # GPG 🔒
    "$HOME/.gnupg"
)

backup_file() {
    local file=$1
    if [ -e "$file" ]; then
        local rel_path=${file#$HOME/}
        local backup_path="$backup_dir/$rel_path"
        mkdir -p "$(dirname "$backup_path")"
        cp -R "$file" "$backup_path"
        echo "✅ Backed up: $rel_path"
    fi
}

echo "🚀 Starting backup process..."
for item in "${backup_items[@]}"; do
    backup_file "$item"
done

echo "📦 Compressing backup..."
tar -czf "$backup_dir.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"

echo "
✨ Backup completed! ✨
📍 Location: $backup_dir.tar.gz

🔍 Summary of backed up items:
- SSH Keys and Config 🔑
- Git Configuration 📦
- Shell Settings 🐚
- VPN Configuration 🔐
- AWS Credentials ☁️
- GPG Keys 🔒
"
