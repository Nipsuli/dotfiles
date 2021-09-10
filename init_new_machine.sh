#!/bin/bash
set -e
source ./helpers.sh

install_package_managers() {
    # install homebrew https://brew.sh
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # These might be needed, not sure
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch --unshallow
    # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    brew install mas                        # Commandline tool for App Store
    # brew install mas-cli/tap/mas          # this is needed on older macs
}

setup_git() {
    check_email_var
    git config --global user.email $EMAIL
    ssh-keygen -t rsa -b 4096 -C $EMAIL    
    brew install gh                         # In addition config GitHub cli
    gh auth login                           # This will also upload ssh key to GitHub
}

setup_keybindings() {
    # I use US layout but need to write Finnish often, and ¨ + a/o is awkward to type
    # so map alt + a/o to ä and ö
    # This will overwrite ø and å (If I remember correctly)
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

configure_settings() {
    # who the hell thought that Desktop would be good location for screenshots?
    mkdir ~/Desktop/screenshots
    defaults write com.apple.screencapture location ~/Desktop/screenshots
    killall SystemUIServer    
    # Some sanity to finder, like showing also hidden files and full paths
    defaults write com.apple.finder AppleShowAllFiles YES
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
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
    # install_package_managers
    # setup_git
    # setup_keybindings
    # configure_settings
    # setup_basic_env
    read -n 1 -s -r -p "Need to login to AppStore manually, press any key to continue"
    open -a App\ Store
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi