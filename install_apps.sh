#!/bin/bash
set -e
source ./helpers.sh

install_apps::terminal() {
    # Make commandline nicer and better
    brew install exa                            # better nicer looking ls
    brew install fzf                            # fzf is a must! https://github.com/junegunn/fzf
    $(brew --prefix)/opt/fzf/install
    brew install ripgrep                        # as is rg
    brew install the_silver_searcher            # and ag for searching 
    brew install bat                            # just better looking cat
    brew install tty-clock                      # sometimes one just wants a simple clock
    # check for more possible goodies: https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4

    # install terminal tools that I prefer
    brew install alacritty                      # alacritty is IMO the best terminal on Mac because one can make it completely disappear
    brew install tmux                           # I feel that tmux as multiplexer makes my life enjoyable
    brew install reattach-to-user-namespace     # this next was needed at least before for tmux copy, not 100% any more 
    brew install vim                            # are there any other editors?
    brew install neovim                         # ah this one, does this do anything better than just vim? Trying to find out

    # Finally look and feel
    brew install starship                       # I like this one https://starship.rs for the basic shell look and feel
    helpers::append_to_shell_files 'eval "$(starship init %SHELL_NAME%)"'
    brew tap homebrew/cask-fonts                # starship requires https://www.nerdfonts.com
    brew install --cask font-hack-nerd-font     # these are my favourite
    brew install --cask font-fira-code          # 
    # On VSCode set terminal font family to Hack Nerd Font Mono
}

install_apps::security() {
    mas install 926036361                   # LastPass
    brew install lastpass-cli               # cli version is nice as well, Note also https://github.com/lastpass/lastpass-cli/issues/604
    brew install --cask cloudflare-warp     # VPN that's not VPN
    mas install 1451685025                  # Wireguard
    brew install --cask gpg-suite           # gpg is good, one should e.g. sign their commits, setup:
    # 1. Generate new key in gpg
    # 2. add public key to gh at https://github.com/settings/keys
    # 3. list keys with gpg --list-secret-keys --keyid-format=long 
    # 4. add keys to git with git config --global user.signingkey <keyid>
    # 5. use -S flag when commiting
}

install_apps::utilities() {}
    brew install --cask spotify             # ¡La Musica!
    brew install --cask rectangle           # window manager, NOTE: could try https://emmetapp.com at some point
    mas install 688211836                   # EasyRes every once and while you'll need non standard resolutions
    # mas purchase 1319778037               # iStat Menus, i've used the brew version and manual licence
    brew install --cask istat-menus         # simple menubar system monitoring tool
    mas purchase 414568915                  # Key Codes, useful when one needs the hex code of key combos
    brew install --cask pingplotter         # Don't you hate bad internet connection? Find where the bottleneck is with Ping Plotter!
    brew install --cask disk-inventory-x    # find disk usage
}

install_apps::productivity() {
    # mas purchase 406056744                # Evernote, nope, not any more my note taking app
    brew install --cask obsidian            # better than Evernote
    mas install 1274495053                  # MS ToDo, I used to use Wunderlist, but MS bought it, and basically made ToDo from that. 
    # mas purchase 975937182                # Fantastical, I've bought licence online, 
    brew install --cask fantastical         # so need to download manually to keep licence
}

install_apps::messengres() {}
    mas install 1176895641                  # Spark, email app, highly recommend this one!
    mas install 803453959                   # Slack
    mas install 747648890                   # Telegram
    brew install --cask discord             # For cool kids
}

install_apps::browsers() {
    brew install --cask vivaldi             # My #1 browser
    brew install --cask google-chrome       # but I guess one always needs couple extras
    brew install --cask firefox             # like this one
    brew install --cask opera               # and what is computer without Opera
    brew install --cask opera-gx            # finally, a gamer needs a gaming browser
}

install_apps::dev_stuff() {
    # Basics 
    brew install gh                         # GitHub cli is amazing
    brew install --cask docker              # one should probably use docker for all dev stuff and run nothing on local machine
    brew install --cask virtualbox          # even though everything is containered in 202X one might need VM's, ASDF requires restart, but that can be delayed
    # Extra editors
    brew install --cask sublime-text        # sometimes sublime is what one needs
    brew install --cask visual-studio-code  # and other times it's VSCode
    helpers::append_to_shell_files 'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'
    # Basic scripting languages
    brew install deno                       # my current favourite scripting language/environment
    brew install poetry                     # best way to manage python projects
    brew install pyenv                      # Manging python versions without this is PITA
    helpers::append_to_shell_files 'export PYENV_ROOT="$HOME/.pyenv"'
    helpers::append_to_shell_files 'export PATH="$PYENV_ROOT/bin:$PATH"'
    helpers::append_to_shell_files 'eval "$(pyenv init --path)"'
    brew install nvm                        # Managing node versions without this is PITA
    mkdir ~/.nvm
    helpers::append_to_shell_files 'export NVM_DIR="$HOME/.nvm"'
    helpers::append_to_shell_files '[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm'
    helpers::append_to_shell_files '[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion'
    # Helpers
    brew install direnv                     # Makes it possibile to scope environment variables to dirs, check more from: https://direnv.net
    helpers::append_to_shell_files 'eval "$(direnv hook %SHELL_NAME%)"'
    # extra utils
    # gnu versions
    brew install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep
    brew install dmg2img
    brew install wget
    brew install gzip
}

install_apps::vscode_extensions() {
    # This does not contain all, VSCode is too sneaky
    code --install-extension iocave.customize-ui     # to be able to get rid of title bar
    code --install-extension VSCodeVim.Vim           # well, who doesn't want vim?
}

install_apps::scripts() {
    mkdir -p ~/bin
    ln -sf $PWD/scripts/mtwrfsu ~/bin/mtwrfsu
    ln -sf $PWD/scripts/git-clean ~/bin/git-clean
    # lpass cli is not enough, this fixes the missing parts
    ln -sf $PWD/scripts/lpass-copy ~/bin/lpass-copy
    # command line cheat sheet
    curl https://cht.sh/:cht.sh > ~/bin/cht.sh
    chmod +x ~/bin/cht.sh
    brew install rlwrap
}

install_apps::main() {
    install_apps::terminal
    install_apps::security
    install_apps::utilities
    install_apps::productivity
    install_apps::messengres
    install_apps::browsers
    install_apps::dev_stuff
    install_apps::vscode_extensions
    install_apps::scripts
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_apps::main "$@"
fi