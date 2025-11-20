#!/bin/bash

# --- CORES E LOGS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}#########################################################${NC}"
echo -e "${BLUE}#    PROJETO NUKE: ARCH ZEN + HYPRLAND + NVIDIA AI      #${NC}"
echo -e "${BLUE}#########################################################${NC}"
sleep 2

# Verificar se NÃO é root (o yay não deve ser rodado como root)
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}ERRO: Executa como utilizador normal (sem sudo).${NC}"
  echo -e "${RED}O script pedirá a senha quando for necessário.${NC}"
  exit 1
fi

# --- FUNÇÕES AUXILIARES ---
install_pkg() {
    if ! pacman -Qi $1 &> /dev/null; then
        echo -e "${GREEN}[PACMAN] A instalar: $1${NC}"
        sudo pacman -S --noconfirm $1
    else
        echo -e "${BLUE}[OK] $1 já instalado.${NC}"
    fi
}

install_aur() {
    if ! pacman -Qi $1 &> /dev/null; then
        echo -e "${GREEN}[AUR] A instalar: $1${NC}"
        yay -S --noconfirm $1
    else
        echo -e "${BLUE}[OK] $1 já instalado.${NC}"
    fi
}

# --- 0. PREPARAÇÃO CRÍTICA (MULTILIB) ---
# Necessário para Steam, Wine e bibliotecas 32bit da Nvidia
echo -e "\n${BLUE}>>> 0. A verificar Repositório Multilib${NC}"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${YELLOW}[AVISO] A ativar repositório Multilib...${NC}"
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
else
    echo -e "${BLUE}[OK] Multilib já ativo.${NC}"
fi

# --- 1. BASE DO SISTEMA & KERNELS ---
echo -e "\n${BLUE}>>> 1. A instalar Kernels (Zen + LTS) e Base${NC}"
sudo pacman -Syu --noconfirm

# Instalação dos Kernels e HEADERS (Obrigatório para Nvidia DKMS)
install_pkg linux-zen
install_pkg linux-zen-headers
install_pkg linux-lts
install_pkg linux-lts-headers
install_pkg base-devel
install_pkg git
install_pkg ntfs-3g

# Instalar YAY (AUR Helper)
if ! command -v yay &> /dev/null; then
    echo -e "${GREEN}[+] A compilar YAY...${NC}"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo -e "${BLUE}[OK] YAY já instalado.${NC}"
fi

# --- 2. NVIDIA DRIVERS (DKMS) ---
echo -e "\n${BLUE}>>> 2. A instalar Stack NVIDIA (DKMS)${NC}"
# nvidia-dkms compila o módulo para o kernel Zen e LTS automaticamente
install_pkg nvidia-dkms
install_pkg nvidia-utils
install_pkg nvidia-settings
install_pkg opencl-nvidia
install_pkg lib32-nvidia-utils

# --- 3. HYPRLAND & RICING ---
echo -e "\n${BLUE}>>> 3. A instalar Hyprland e Ferramentas${NC}"
install_pkg hyprland
install_pkg waybar
install_pkg wofi
install_pkg mako           # Notificações
install_pkg swaybg         # Wallpaper
install_pkg swayidle
install_pkg swaylock
install_pkg sddm           # Login Manager
install_pkg xorg-xwayland
install_pkg polkit-kde-agent
install_pkg wl-clipboard
install_pkg grim           # Screenshots
install_pkg slurp          # Seleção de área
install_pkg ttf-jetbrains-mono-nerd
install_pkg starship       # Prompt ZSH
install_pkg zsh
install_pkg dolphin        # File Manager
install_pkg ark            # Para extrair zip/rar

# Temas e Terminal
install_aur wezterm-git
install_aur python-pywal

# --- 4. FERRAMENTAS DE DEV E IA ---
echo -e "\n${BLUE}>>> 4. A instalar Dev Stack & AI Tools${NC}"
install_pkg docker
install_pkg docker-compose
install_pkg python-pip
install_pkg nodejs
install_pkg npm
install_pkg neovim
install_pkg btop
install_pkg nvtop   # Monitor GPU
install_pkg git-delta
install_pkg tmux
install_pkg unzip
install_pkg wget

# Navegador e IDE
install_aur google-chrome
install_aur visual-studio-code-bin

# --- 5. INSTALAÇÕES GLOBAIS NPM (CLI) ---
echo -e "\n${BLUE}>>> 5. A instalar CLIs via NPM${NC}"
# Nota: Usar sudo npm -g não é "best practice" no Arch, mas funciona para setups rápidos.
sudo npm install -g @google/gemini-cli
sudo npm install -g @salesforce/cli

# --- 6. CONFIGURAÇÕES DO SISTEMA (FIX NVIDIA) ---
echo -e "\n${BLUE}>>> 6. A aplicar Fixes de NVIDIA e Boot${NC}"

# Backup dos ficheiros originais
[ ! -f /etc/mkinitcpio.conf.bak ] && sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
[ ! -f /etc/default/grub.bak ] && sudo cp /etc/default/grub /etc/default/grub.bak

# 6.1 Configurar MKINITCPIO (Carregar módulos cedo)
if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
    echo -e "${GREEN}[CONF] A adicionar módulos NVIDIA ao mkinitcpio...${NC}"
    sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
fi

# 6.2 Configurar GRUB (DRM Modeset)
if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    echo -e "${GREEN}[CONF] A adicionar nvidia-drm ao GRUB...${NC}"
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 6.3 Variáveis de Ambiente (Hyprland + Nvidia)
echo -e "${GREEN}[CONF] A criar /etc/profile.d/hyprland-nvidia.sh...${NC}"
cat <<EOF | sudo tee /etc/profile.d/hyprland-nvidia.sh
export LIBVA_DRIVER_NAME=nvidia
export XDG_SESSION_TYPE=wayland
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVD_BACKEND=direct
export ELECTRON_OZONE_PLATFORM_HINT=auto
EOF

# 6.4 Ativar Serviços
echo -e "${GREEN}[CONF] A ativar serviços systemd...${NC}"
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
sudo systemctl enable sddm

# --- 7. SETUP N8N (DOCKER) ---
echo -e "\n${BLUE}>>> 7. A configurar Atalho n8n${NC}"
mkdir -p ~/ia-tools/n8n
cat <<EOF > ~/ia-tools/n8n/start-n8n.sh
#!/bin/bash
if ! docker ps | grep -q n8n; then
    echo "A iniciar contentor n8n..."
    docker run -d --restart unless-stopped --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8n/n8n
else
    echo "n8n já está a correr."
fi
echo "Abre o browser em: http://localhost:5678"
EOF
chmod +x ~/ia-tools/n8n/start-n8n.sh

echo -e "${GREEN}#########################################################${NC}"
echo -e "${GREEN}#           NUKE CONCLUÍDO COM SUCESSO! ☢️              #${NC}"
echo -e "${GREEN}#########################################################${NC}"
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo -e "1. Ao reiniciar, no menu do GRUB, seleciona 'Arch Linux (linux-zen)' para melhor performance."
echo -e "2. Se falhar, usa 'Arch Linux (linux-lts)'."
echo -e "3. O Hyprland deve iniciar após o login no SDDM."
echo -e "\nA reiniciar em 10 segundos... (CTRL+C para cancelar)"
sleep 10
sudo reboot
