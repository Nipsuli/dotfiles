#!/bin/bash
set -e
source ./helpers.sh

init_machine::install_package_managers() {
    if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
        test -d "${xpath}" && test -x "${xpath}" ; then
        echo "xcode command line tools already installed!"
    else
        echo "Installing xcode command line tools"
        xcode-select --install
    fi
    if type brew >&- ; then
        echo "brew already installed"
    else
        echo "Installing homebrew, this might take tiem, read more from https://brew.sh"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # These might be needed, not sure
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
    # git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch --unshallow
    # /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    brew install mas                        # Commandline tool for App Store
    # brew install mas-cli/tap/mas          # this is needed on older macs

    if mas account >&- ; then
        echo "You've logged in in app store"
    else
        read -n 1 -s -r -p "Need to login to AppStore manually, press any key to continue\n"
        open -a App\ Store
        read -n 1 -s -r -p "press any key to continue\n"
    fi
}

init_machine::setup_git() {
    helpers::check_email_var
    git config --global user.email $EMAIL
    ssh-keygen -t rsa -b 4096 -C $EMAIL    
    brew install gh                             # In addition config GitHub cli
    gh auth login                               # This will also upload ssh key to GitHub
    brew install --cask gpg-suite               # gpg is good for other things as well, butone should definitely sign their commits
    gpg --quick-generate-key $EMAIL
    read -n 1 -s -r -p "We will push the public key to to clipboard and open github for you to add the key. Press any key to continue"
    echo
    local keyid=$(gpg --list-signatures --with-colons | grep 'sig' | grep $EMAIL | head -n 1 | cut -d':' -f5) # | xargs gpg --export -a | pbcopy
    gpg --export -a $keyid | pbcopy
    open https://github.com/settings/gpg/new
    read -n 1 -s -r -p "Continue after you've set up the key. Press any key to continue"
    echo
    git config --global user.signingkey $keyid
    git config --global commit.gpgsign true
}

init_machine::setup_keybindings() {
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

init_machine::configure_system_preferences() {
    # Never configure stuff from GUI, store all settings here
    # How to find correct setting path:
    # https://pawelgrzybek.com/change-macos-user-preferences-via-command-line/
    # Simplest way to find correct setting:
    # 1. defaults read > before
    # 2. togle the setting in UI
    # 3. defaults read > before
    # 4. diff files

    # Who the hell thought that Desktop would be good location for screenshots?
    mkdir ~/Desktop/screenshots
    defaults write com.apple.screencapture location ~/Desktop/screenshots
    # Some sanity to finder, like showing also hidden files and full paths
    defaults write com.apple.finder AppleShowAllFiles YES
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    # I don't like apples clock on the menu bar and on BigSur and one cannot remove
    # it, so best what I can do is to make it a small analog clock instead
    defaults write com.apple.menuextra.clock IsAnalog -bool true
    # Disable smart dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    # Disable automatic periods with a double space
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    # Disable smart quotes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    # Set a shorter delay until key repeat:
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    # Set a blazingly fast keyboard repeat rate:
    defaults write NSGlobalDomain KeyRepeat -int 2

    # Hide dock to right so it won't take half of the screen
    defaults write com.apple.dock autohide  int 1
    defaults write com.apple.dock orientation right
    defaults write com.apple.dock titlesize -int 16

    echo "restarting applications" 
    killall SystemUIServer
    killall Finder
    killall Dock
}

init_machine::setup_basic_env() {
    # I think having $EMAIL as global env variable helps
    helpers::check_email_var
    helpers::append_to_shell_files "export EMAIL=${EMAIL}"
}

init_machine::main() {
    init_machine::install_package_managers
    init_machine::setup_git
    init_machine::setup_keybindings
    init_machine::configure_system_preferences
    init_machine::setup_basic_env
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_machine::main "$@"
fi