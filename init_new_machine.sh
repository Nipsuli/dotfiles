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
    # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Commandline tool for app store
    brew install mas
    # brew install mas-cli/tap/mas # this is needed on older macs
}

setup_git() {
    check_email_var
    git config --global user.email $EMAIL
    ssh-keygen -t rsa -b 4096 -C $EMAIL    
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

setup_menubar() {
    # I don't like apples clock on the menu bar on BigSur
    # and one cannot remove it, so best what I can do is
    # to make int small analog clock instead
    defaults write com.apple.menuextra.clock IsAnalog -bool true
}

setup_basic_env() {
    check_email_var
    append_to_shell_files "export EMAIL=${EMAIL}"
}

main() {
    install_package_managers
    setup_git
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