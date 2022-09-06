export ZSH="$HOME/.oh-my-zsh"
export EDITOR='nvim'
export PATH="/home/julien/.local/bin:$PATH"

ZSH_THEME="robbyrussell" # set by `omz`

plugins=(git zsh-autosuggestions zsh-syntax-highlighting colored-man-pages colorize vi-mode)

source $ZSH/oh-my-zsh.sh

# Enable Vi mode and settings
bindkey -v
export VI_MODE_SET_CURSOR=true
export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
export MODE_INDICATOR="%B%K{2}%F{0} NORMAL %f%k%b"

### Aliases ###
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias vim="nvim"
alias v="nvim"
alias jujxb3="figlet -c -f 3D-ASCII 'Jujxb3'"
 
# Directory aliases
alias nvimcfg="cd ~/.config/nvim"
alias kittycfg="cd ~/.config/kitty"
alias qtilecfg="cd ~/.config/qtile"

# Dotfiles aliases
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
