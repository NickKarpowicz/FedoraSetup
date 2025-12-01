#!/bin/bash
set -eu

echo "Enabling RPM Fusion repositories and installing codecs..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
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


if lspci | grep -qi "VGA compatible controller: NVIDIA"; then
    echo "NVIDIA GPU detected. Installing drivers..."
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    echo "NVIDIA drivers installed. Please reboot after script completion."
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

sudo dnf install nextcloud-client nextcloud-client-dolphin
sudo dnf install texlive-scheme-medium kile

flatpak install flathub io.github.NickKarpowicz.LightwaveExplorer
flatpak install flathub dev.zed.Zed
flatpak install flathub org.onlyoffice.desktopeditors
flatpak install flathub de.easyroam.easyroam

pip install attoworld


if [ ! -f ~/.local/share/kio/servicemenus/marimomenu.desktop ]; then
mkdir -p ~/.local/share/kio/servicemenus
cat > ~/.local/share/kio/servicemenus/marimomenu.desktop << 'EOF'
[Desktop Entry]
Type=Service
Actions=EditInMarimo;
MimeType=text/x-python;

[Desktop Action EditInMarimo]
Name=Edit in Marimo
Exec=konsole -e bash -c "marimo edit --sandbox '%F'; exec bash"
Icon=utilities-terminal
EOF
fi


echo "Everything is installed! please restart..."
