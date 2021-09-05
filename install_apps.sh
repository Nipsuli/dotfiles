#!/bin/bash
set -e

install_from_brew () {
    # basics
    brew install --cask rectangle           # window manager
    brew install lastpass-cli               # my choise of password manager, Note also https://github.com/lastpass/lastpass-cli/issues/604
    brew install --cask cloudflare-warp     # VPN that's not VPN
    brew install --cask istat-menus         # simple menubar system monitoring tool
    brew install --cask spotify             # ¡La Musica!
    # browsers
    brew install --cask vivaldi             # My #1 browser
    brew install --cask google-chrome       # but I guess one always needs couple extras
    brew install --cask firefox             # like this one
    brew install --cask opera               # and what is computer without Opera
    brew install --cask opera-gx            # gamer needs gaming browser
    # dev stuff
    brew install --cask docker              # one should probably use docker for all dev stuff
    brew install --cask sublime-text        # sometimes sublime is what one needs
    brew install --cask visual-studio-code  # and other times it's VSCode
}

install_personal_helpers() {
    # lpass cli is not enough, this fixes alla
    ln -sf $PWD/scripts/lpass-copy ~/bin/lpass-copy
    # command line cheat sheet
    mkdir -p ~/bin
    curl https://cht.sh/:cht.sh > ~/bin/cht.sh
    chmod +x ~/bin/cht.sh
    brew install rlwrap
}

install_from_app_store() {
    mas install 1176895641  # Spark email app
    mas install 803453959   # Slack 
    mas install 747648890   # Telegram
    mas install 1274495053  # MS To Do 
    mas install 926036361   # LastPass
    mas purchase 406056744  # Evernote
    # might have purchased this else where
    # mas purchase 1319778037 # iStat Menus 
    # I've purchased this from online, so need to download manually to keep licence
    # mas purchase 975937182  # Fantastical
    mas install 1451685025  # Wireguard
}

main() {
    install_from_brew
    install_from_app_store
    install_personal_helpers
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi