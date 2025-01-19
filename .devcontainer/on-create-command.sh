#!/bin/bash

source .devcontainer/_functions.sh;

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
    postgresql-common;

# Install postgresql-client 16
sudo YES=true /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh;
sudo apt-get update;
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y postgresql-client-16;

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
