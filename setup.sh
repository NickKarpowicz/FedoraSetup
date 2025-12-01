#!/bin/bash
set -eu

echo "Enabling RPM Fusion repositories and installing codecs..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

if lspci | grep -qi "VGA compatible controller: NVIDIA"; then
    if mokutil --sb-state 2>/dev/null | grep -qi enabled; then
        echo "You need to disable Secure Boot in the BIOS or Nvidia will break!"
        exit 1
    fi
    echo "NVIDIA GPU detected. Installing drivers..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
fi

sudo dnf group install -y multimedia --exclude=PackageKit-gstreamer-plugin
sudo dnf group install -y sound-and-video
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf install -y lame\* --exclude=lame-devel
sudo dnf install -y ffmpeg ffmpeg-libs --allowerasing

echo "Configuring Flatpak remotes..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
if flatpak remotes | grep -qi "fedora"; then
    flatpak remote-delete fedora --force >/dev/null 2>&1 || true
fi




echo "Installing powerline..."
sudo dnf install -y powerline source-foundry-hack-fonts powerline-fonts
if ! grep -q "powerline-daemon" ~/.bashrc; then
    cat << 'EOF' >> ~/.bashrc
if [ -f "$(which powerline-daemon)" ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi
EOF
fi

echo "Installing grub2 theme..."
git clone https://github.com/vinceliuice/grub2-themes
cd grub2-themes
sudo ./install.sh -t vimix -s 1080p
cd ..
rm -rf grub2-themes

echo "Installing dnf application and development packages..."
sudo dnf install -y nextcloud-client nextcloud-client-dolphin seafile seafile-client
sudo dnf install -y texlive-scheme-medium kile
sudo dnf install -y uv ruff maturin

echo "Installing flatpaks..."
flatpak install --system --assumeyes --noninteractive flathub io.github.NickKarpowicz.LightwaveExplorer
flatpak install --system --assumeyes --noninteractive flathub dev.zed.Zed
flatpak install --system --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
flatpak install --system --assumeyes --noninteractive flathub de.easyroam.easyroam

pip install attoworld


if [ ! -f ~/.local/share/kio/servicemenus/marimomenu.desktop ]; then
mkdir -p ~/.local/share/kio/servicemenus
cat > ~/.local/share/kio/servicemenus/marimomenu.desktop << 'EOF'
[Desktop Entry]
Type=Service
Actions=EditInMarimo;
MimeType=text/x-python;
X-KDE-Priority=TopLevel

[Desktop Action EditInMarimo]
Name=Edit in Marimo
Exec=konsole -e bash -c "marimo edit --sandbox '%F'; exec bash"
Icon=utilities-terminal
EOF
fi
chmod +x ~/.local/share/kio/servicemenus/marimomenu.desktop


sudo reboot
