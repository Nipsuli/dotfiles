#!/bin/bash
set -e
source ./helpers.sh

link_dotfiles() {
    ln -sf $PWD/dotfiles/.bash_profile_shared ~/.bash_profile_shared
    # On purpose keeping the the bash_profile_shared as clean and sourcing
    # it on the main shell config file, as many installations can push
    # all kinds of junk to the rc files
    append_to_shell_files "source ~/.bash_profile_shared"
    ln -sf $PWD/dotfiles/.tmux.conf ~/.tmux.conf
    ln -sf $PWD/dotfiles/.vimrc ~/.vimrc
}

link_other_config_files() {
    ln -sf $PWD/dotfiles/.alacritty.yml ~/.alacritty.yml
}

install_vim_plugins() {
    # I prefer Plug as vim plugin manager
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    brew install cmake python mono go nodejs    # I use https://github.com/ycm-core/YouComplete as vim autocomplete, install all dependencies
    vim +'PlugInstall --sync' +qa               # Install vim plugins

    # Install YouCompleteMe
    local curr_dir=$PWD
    cd ~/.vim/plugged/YouCompleteMe/
    python3 install.py --all 
    cd $curr_dir
}

install_tmux_plugins() {
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tmp
    tmux new -s install_session '~/.tmux/plugins/tpm/tpm && ~/.tmux/plugins/tpm/bindings/install_plugins'
}

main() {
    link_dotfiles
    link_other_config_files
    install_vim_plugins
    install_tmux_plugins
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi