#!/bin/bash

source .devcontainer/_functions.sh;
source ~/.asdf/asdf.sh;

# Imported from _functions.sh
set_erlang_locale;

# Install asdf plugins and toolchain versions
install_asdf_plugins;

# Install hex and rebar
mix do local.hex --force --if-missing, local.rebar --force --if-missing;

# Copy the .tool-versions file to the home directory for RefactorEX
cp .tool-versions ~/.tool-versions;