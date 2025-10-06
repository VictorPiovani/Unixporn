#!/bin/bash
set -e

echo "=== Atualizando sistema e instalando pacotes essenciais ==="
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm \
    polybar rofi picom feh kitty alacritty zsh git \
    neovim vim pipewire pipewire-pulse pipewire-alsa wireplumber \
    base-devel python-pywal

# === Criando diretórios de configuração ===
echo "=== Criando diretórios de configuração ==="
mkdir -p ~/.config/bspwm ~/.config/sxhkd ~/.config/polybar ~/.config/picom ~/.config/kitty ~/.config/zsh ~/.config/neovim ~/.Pictures/Wallpapers

# === Script autodesktop ===
cat > ~/.config/bspwm/autodesktop.sh <<'EOF'
#!/bin/bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
TERMINAL="kitty"

# Escolhe wallpaper aleatório
WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Aplica wallpaper e paleta
feh --bg-scale "$WALLPAPER"
wal -i "$WALLPAPER"

# Inicia compositor
picom --config ~/.config/picom/picom.conf &

# Inicia polybar
~/.config/polybar/launch.sh &

# Terminal de teste
$TERMINAL &
EOF
chmod +x ~/.config/bspwm/autodesktop.sh

# === bspwmrc ===
cat > ~/.config/bspwm/bspwmrc <<'EOF'
#!/bin/sh
~/.config/bspwm/autodesktop.sh &
bspc config border_width 2
bspc config window_gap 10
bspc config focus_follows_pointer true
EOF
chmod +x ~/.config/bspwm/bspwmrc

# === sxhkdrc ===
cat > ~/.config/sxhkd/sxhkdrc <<'EOF'
super + Return
    kitty
super + d
    rofi -show drun
super + q
    bspc node -c
super + {1-9}
    bspc desktop -f {1-9}
super + shift + {1-9}
    bspc node -d {1-9}
super + w
    ~/.config/bspwm/autodesktop.sh
EOF

# === Polybar ===
cat > ~/.config/polybar/config <<'EOF'
[colors]
background = #1E1E1E
foreground = #FFFFFF
accent = #FF9500

[bar/example]
width = 100%
height = 30
background = ${colors.background}CC
foreground = ${colors.foreground}
modules-left = bspwm
modules-right = cpu memory date
EOF

cat > ~/.config/polybar/launch.sh <<'EOF'
#!/bin/bash
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done
polybar example &
EOF
chmod +x ~/.config/polybar/launch.sh

# === Picom ===
cat > ~/.config/picom/picom.conf <<'EOF'
backend = "glx";
vsync = true;
blur-method = "dual_kawase";
blur-strength = 7;
shadow = true;
shadow-radius = 10;
shadow-offset-x = -10;
shadow-offset-y = -10;
fading = true;
fade-delta = 10;
inactive-opacity = 0.85;
active-opacity = 1.0;
EOF

# === Kitty ===
cat > ~/.config/kitty/kitty.conf <<'EOF'
background #1E1E1E
foreground #FFFFFF
cursor #FF9500
selection_background #FFA733
font_family FiraCode Nerd Font
font_size 13.5
scrollback_lines 10000
enable_csi_u_key_encoding yes
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
EOF

# === Zsh + Oh-My-Zsh ===
echo "=== Instalando Oh-My-Zsh e plugins ==="
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
