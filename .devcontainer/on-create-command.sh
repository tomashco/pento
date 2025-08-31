#!/bin/bash

source .devcontainer/_functions.sh;

# Add non-free to debian
sudo sed -i 's/Components: main/Components: main non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources

sudo apt-get update;
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
    autoconf \
    automake \
    build-essential \
    curl \
    fop \
    gnupg2 \
    inotify-tools \
    libc6-dev \
    libncurses-dev \
    libsodium-dev \
    libssh-dev \
    libxml2-utils \
    m4 \
    xsltproc \
    postgresql-common \
    pkg-config \
    libssl-dev && rm -rf /var/lib/apt/lists/* \
    libsrtp2-dev \
    libvpx-dev \
    libfdk-aac-dev \
    libmp3lame-dev \
    libmad0-dev \
    libopus-dev

# symlink lame.pc to mp3lame.pc for membrane
sudo ln -s /usr/lib/aarch64-linux-gnu/pkgconfig/lame.pc /usr/lib/aarch64-linux-gnu/pkgconfig/mp3lame.pc

# Install postgresql-client 16
sudo YES=true /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh;
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y postgresql-client-16 

# set PKG_CONFIG_PATH for librstp2
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

# Imported from _functions.sh
set_erlang_locale;

# Prepare direnv
mkdir -p ~/.config/direnv;
touch ~/.config/direnv/direnv.toml;
echo "[whitelist]" >> ~/.config/direnv/direnv.toml;
echo "prefix = [\"/workspaces/pravda\"]" >> ~/.config/direnv/direnv.toml;

# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1;
persist ". ~/.asdf/asdf.sh";
source ~/.asdf/asdf.sh;

# Imported from _functions.sh
install_asdf_plugins;

# Install Pluralith
sudo wget -O /usr/local/bin/pluralith https://github.com/Pluralith/pluralith-cli/releases/download/v0.2.2/pluralith_cli_linux_amd64_v0.2.2
sudo chmod +x /usr/local/bin/pluralith
