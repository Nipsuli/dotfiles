#!/bin/bash
set -e
source ./helpers.sh

link_dotfiles() {
    ln -sf $PWD/dotfiles/.alacritty.yml ~/.alacritty.yml
    ln -sf $PWD/dotfiles/.bash_profile_shared ~/.bash_profile_shared
    ln -sf $PWD/dotfiles/.tmux.conf ~/.tmux.conf
    ln -sf $PWD/dotfiles/.vimrc ~/.vimrc

    # bash or zsh both works
    # this repo has shared bash profile that's sourced in the real
    # ~/.bash_profile or ~/.zshrc as lot of installations pollute
    # those files and don't want to link that to this repo
    touch ~/.bash_profile
    touch ~/.zshrc
    append_to_file ~/.bash_profile "source ~/.bash_profile_shared"
    append_to_file ~/.zshrc "source ~/.bash_profile_shared"
}

main() {
    link_dotfiles
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi