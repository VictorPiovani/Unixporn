#!/bin/bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

cat > ~/.zshrc <<'EOF'
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
alias ll='ls -lah'
alias gs='git status'
alias gp='git pull'
alias gco='git checkout'
EOF

# === Neovim ===
mkdir -p ~/.config/neovim/colors
cat > ~/.config/neovim/init.vim <<'EOF'
set number
set relativenumber
syntax enable
set background=dark
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set cursorline
colorscheme gruvbox
set guifont=FiraCode\ Nerd\ Font:h13
set mouse=a
EOF

echo "=== Configuração desktop concluída! Coloque wallpapers em ~/Pictures/Wallpapers e reinicie/startx ==="
