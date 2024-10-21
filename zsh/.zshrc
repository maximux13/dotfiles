export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH_FOLDER=$HOME/.config/zsh
export PATH=$PATH:$ZSH_FOLDER/scripts
export HOMEBREW_NO_ANALYTICS=1

source $ZSH_FOLDER/nvm
source $ZSH_FOLDER/zinit

source $ZSH_FOLDER/keybindings
source $ZSH_FOLDER/history
source $ZSH_FOLDER/functions
source $ZSH_FOLDER/aliases
source $ZSH_FOLDER/completions

source $ZSH_FOLDER/android
source $ZSH_FOLDER/oh-my-posh
source $ZSH_FOLDER/pkgx
source $ZSH_FOLDER/ruby

source $ZSH_FOLDER/zstyle

source $ZSH_FOLDER/fzf
source $ZSH_FOLDER/zoxide

if command -v fastfetch &> /dev/null; then
  fastfetch
fi
