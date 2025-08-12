# -------------------------
# Check if Homebrew is installed, if not, install it.
# -------------------------
if ! command -v brew &> /dev/null
then
    echo "Homebrew not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Homebrew installed. Updating Homebrew..."
brew update

echo "Installing Homebrew packages..."

# -------------------------
# Leaves
# -------------------------

# Git and GitHub
brew install git
brew install gh
brew install git-standup

# Node and Package Managers
brew install nvm
brew install pnpm
brew install yarn
brew install pkgxdev/made/pkgx

# Shell and Utilities
brew install zsh
brew install fzf
brew install zoxide
brew install stow
brew install coreutils
brew install jandedobbeleer/oh-my-posh/oh-my-posh
brew install lsd
brew install gitui

# Cloud and Deployment
brew install awscli
brew install flyctl
brew install supabase/tap/supabase

# Miscellaneous Utilities
brew install jq
brew install ffmpeg
brew install fastfetch
brew install tpm
brew install act

# -------------------------
# Casks
# -------------------------

# Daily
brew install --cask 1password
brew install --cask ghostty
brew install --cask slack-cli
brew install --cask rectangle
brew install --cask raycast

# Browsers
brew install --cask arc
brew install --cask firefox
brew install --cask google-chrome
brew install --cask brave-browser

# Development
brew install --cask orbstack
brew install --cask android-studio
brew install --cask ngrok

# Messaging
brew install --cask signal
brew install --cask zoom

# Fonts
brew install --cask font-hasklug-nerd-font
brew install --cask font-lilex-nerd-font
brew install --cask font-monaspace
brew install --cask font-google-sans-code

# Design
brew install --cask figma

# Misc
brew install --cask appcleaner
brew install --cask surfshark

echo "Homebrew packages installed."
