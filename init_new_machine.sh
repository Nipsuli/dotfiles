#!/bin/bash
set -e

source ./helpers.sh

check_email_var() {
    if [ -z ${EMAIL+x} ]; then
        echo "No EMAIL variable available, bailing"
        exit 1
    fi
}

install_package_managers() {
    # install homebrew https://brew.sh
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # might be needed, not sure
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch --unshallow
    
    # Commandline tool for app store
    brew install mas # this works on newer macs
    # brew install mas-cli/tap/mas # this is needed on older macs
}

setup_git() {
    check_email_var
    git config --global user.email $EMAIL
    ssh-keygen -t rsa -b 4096 -C $EMAIL    
}

setup_terminal() {
    # installing basic console tools that I prefer
    # better nicer looking ls
    brew install exa              
    # I like this one https://starship.rs for the basic shell look and feel
    brew install starship
    # it requires https://www.nerdfonts.com
    # these are my favourites
    brew tap homebrew/cask-fonts
    brew install --cask font-hack-nerd-font 
    brew install --cask font-fira-code
    # On VSCode set terminal font family to Hack Nerd Font Mono

    # I think this is a must https://direnv.net
    # Use .envrc in projects to manage env
    brew install direnv

    # install starship and direnv hooks for both bash and zsh
    touch ~/.bash_profile
    touch ~/.zshrc
    append_to_file ~/.bash_profile 'eval "$(starship init bash)"'
    append_to_file ~/.bash_profile 'eval "$(direnv hook bash)"'
    append_to_file ~/.zshrc 'eval "$(starship init zsh)"'
    append_to_file ~/.zshrc 'eval "$(direnv hook zsh)"'

    # fzf is a must! https://github.com/junegunn/fzf
    brew install fzf
    $(brew --prefix)/opt/fzf/install
    # rg for searching is must
    brew install ripgrep
    # as is ag
    brew install the_silver_searcher
    # better looking cat
    brew install bat
    # check for more possible goodies: https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4
}

setup_terminal_tools() {
    # I like alacritty as terminal
    brew install alacritty
    # and tmux as multiplexer
    brew install tmux
    # this next was needed at least before for tmux copy, not 100% any more 
    brew install reattach-to-user-namespace
    # and vim as editor
    brew install vim
    # plugin managers:
    # for tmux
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # and vim
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

}

setup_keybindings() {
    # I use US layout but need to write Finnish often
    mkdir -p ~/Library/KeyBindings/
    touch ~/Library/KeyBindings/DefaultKeyBinding.dict
    cat > ~/Library/KeyBindings/DefaultKeyBinding.dict << EOF
{
    "~a" = (insertText:, "ä");
    "~o" = (insertText:, "ö");
    "~A" = (insertText:, "Ä");
    "~O" = (insertText:, "Ö");
}
EOF
}

setup_screenshots() {
    # who the hell thought that Desktop would be good location for them?
    mkdir ~/Desktop/screenshots
    defaults write com.apple.screencapture location ~/Desktop/screenshots
    killall SystemUIServer    
}

setup_finder() {
    defaults write com.apple.finder AppleShowAllFiles YES
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
}

setup_helper_scripts() {
    # link helper scripts
    mkdir -p ~/bin
    ln -sf $PWD/scripts/mtwrfsu ~/bin/mtwrfsu
    ln -sf $PWD/scripts/git-clean ~/bin/git-clean
}

setup_basic_env() {
    check_email_var
    append_to_file ~/.bash_profile "export EMAIL=${EMAIL}"
    append_to_file ~/.zshrc "export EMAIL=${EMAIL}"
}

main() {
    # EXECUTE ALL!
    install_package_managers
    setup_git
    setup_terminal
    setup_terminal_tools
    setup_helper_scripts
    setup_keybindings
    setup_finder
    setup_screenshots
    setup_basic_env
    echo "remember to login to AppStore"
    echo "!!! remember to add ssh key to github !!!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi