#!/bin/bash
set -e

source ./helpers.sh

install_terminal_apps() 
    # install basic console tools that I prefer
    brew install alacritty                      # alacritty is IMO best terminal on Mac because one can make it completely disappear
    brew install tmux                           # I feel that tmux as multiplexer makes my life enjoyable
    brew install reattach-to-user-namespace     # this next was needed at least before for tmux copy, not 100% any more 
    brew install vim                            # are there any other editors?
    brew install cmake python mono go nodejs    # I use https://github.com/ycm-core/YouComplete as vim autocomplete, install all dependencies
    # plugin managers:
    # for tmux
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # and vim
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    # Basic command line tools
    brew install exa                            # better nicer looking ls
    brew install fzf                            # fzf is a must! https://github.com/junegunn/fzf
    $(brew --prefix)/opt/fzf/install
    brew install ripgrep                        # as is rg
    brew install the_silver_searcher            # and ag for searching 
    brew install bat                            # just better looking cat
    # check for more possible goodies: https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4

    # Finally look and feel
    brew install starship                       # I like this one https://starship.rs for the basic shell look and feel
    append_to_file ~/.bash_profile 'eval "$(starship init bash)"'
    append_to_file ~/.zshrc 'eval "$(starship init zsh)"'
    brew tap homebrew/cask-fonts                # starship requires https://www.nerdfonts.com
    brew install --cask font-hack-nerd-font     # these are my favourite
    brew install --cask font-fira-code
    # On VSCode set terminal font family to Hack Nerd Font Mono
}

install_apps() {
    # security
    mas install 926036361                   # LastPass
    brew install lastpass-cli               # my choise of password manager, Note also https://github.com/lastpass/lastpass-cli/issues/604
    brew install --cask cloudflare-warp     # VPN that's not VPN
    mas install 1451685025                  # Wireguard
    # utilities 
    brew install --cask spotify             # ¡La Musica!
    brew install --cask rectangle           # window manager
    brew install --cask istat-menus         # simple menubar system monitoring tool
    # mas purchase 1319778037               # iStat Menus, i've used the brew version and manual licence
    mas purchase 414568915                  # Key Codes
    # productivity
    mas purchase 406056744                  # Evernote
    mas install 1274495053                  # MS To Do 
    # mas purchase 975937182                # Fantastical, I've purchased this from online, so need to download manually to keep licence
    # messengres 
    mas install 1176895641                  # Spark email app
    mas install 803453959                   # Slack 
    mas install 747648890                   # Telegram
    brew install --cask discord             # For cool kids
    # browsers 
    brew install --cask vivaldi             # My #1 browser
    brew install --cask google-chrome       # but I guess one always needs couple extras
    brew install --cask firefox             # like this one
    brew install --cask opera               # and what is computer without Opera
    brew install --cask opera-gx            # finallky, a gamer needs a gaming browser
    # dev stuff
    brew install --cask docker              # one should probably use docker for all dev stuff
    brew install --cask sublime-text        # sometimes sublime is what one needs
    brew install --cask visual-studio-code  # and other times it's VSCode
    brew install deno                       # my current favourite scripting language/environment 
    brew install poetry                     # best way to manage python projects
    brew install pyenv                      # Why all stuff needs so many versions?
    append_to_shell_files 'export PYENV_ROOT="$HOME/.pyenv"'
    append_to_shell_files 'export PATH="$PYENV_ROOT/bin:$PATH"'
    append_to_shell_files 'eval "$(pyenv init --path)"'
    brew install nodenv                     # like this one
    append_to_shell_files 'eval "$(nodenv init -)"'
    brew install direnv                     # and I think this is a must https://direnv.net
    append_to_file ~/.zshrc 'eval "$(direnv hook zsh)"'
    append_to_file ~/.bash_profile 'eval "$(direnv hook bash)"'
}

install_helper_scripts() {
    mkdir -p ~/bin
    ln -sf $PWD/scripts/mtwrfsu ~/bin/mtwrfsu
    ln -sf $PWD/scripts/git-clean ~/bin/git-clea
    # lpass cli is not enough, this fixes the missing parts
    ln -sf $PWD/scripts/lpass-copy ~/bin/lpass-copy
    # command line cheat sheet
    curl https://cht.sh/:cht.sh > ~/bin/cht.sh
    chmod +x ~/bin/cht.sh
    brew install rlwrap
}

main() {
    install_terminal_apps
    install_apps
    install_helper_scripts
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi