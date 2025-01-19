#!/bin/bash

persist() {
    echo "$1" | sudo tee -a /etc/bash.bashrc
    echo "$1" | sudo tee -a /etc/zsh/zshrc
}

install_asdf_plugins() {
    # Install asdf plugins and toolchain versions
    cat .tool-versions | cut -d' ' -f1 | grep "^[^\#]" | xargs -i asdf plugin add  {}
    ASDF_NODEJS_AUTO_ENABLE_COREPACK=true asdf install;
    asdf reshim;
}

set_erlang_locale() {
    # Set the locale for the Erlang runtime
    sudo update-locale LC_ALL=en_US.UTF-8;
}
