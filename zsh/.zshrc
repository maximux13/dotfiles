export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export ZSH_FOLDER=$HOME/.config/zsh
export HOMEBREW_NO_ANALYTICS=1

export PATH=$PATH:$ZSH_FOLDER/scripts
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

source $ZSH_FOLDER/fnm
source $ZSH_FOLDER/zinit

source $ZSH_FOLDER/keybindings
source $ZSH_FOLDER/history
source $ZSH_FOLDER/functions
source $ZSH_FOLDER/aliases

source $ZSH_FOLDER/android
source $ZSH_FOLDER/oh-my-posh
source $ZSH_FOLDER/pkgx
source $ZSH_FOLDER/ruby

source $ZSH_FOLDER/zstyle

source $ZSH_FOLDER/fzf
source $ZSH_FOLDER/fastfetch

# pnpm
export PNPM_HOME="/Users/maestrico_/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
