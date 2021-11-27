#!/bin/bash
#######################################
# Collection of functions to be used to setup and confugure personal/work
# computer. Check what you'll need and make them work for you.
#
# <3 @Nipsuli <nipsuli@korvenlaita.fi>
#######################################
set -e

readonly BREW_INSTALL_SCRIPT="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

#######################################
# BEGIN GENERIC HELPERS
#######################################

#######################################
# Ensure EMAIL variable is set. Exits if not availble
# Globals:
#   EMAIL
# Arguments:
#   None
#######################################
nipsulidotfiles::check_email_var() {
  if [[ -z "${EMAIL:=}" ]]; then
    echo "No EMAIL environment variable available, bailing"
    exit 1
  fi
}

#######################################
# Appends text to file if it does not exist in the file yet
# Idempotent: calling multiple times with same arguments results only one
# append to the file
# Asks for sudo for write to allow writing to e.g. /etc/hosts
# TODO(@Nipsuli) perhaps sudo should be split to own argument
# Globals:
#   None
# Arguments:
#   path to file
#   text to append
#######################################
nipsulidotfiles::append_to_file() {
  if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
    echo "Invalid usage, needs 2 argumets: filepath and line to appends"
    exit 1
  fi
  local file="$1"
  local line="$2"
  grep -qF -- "${line}" "${file}" \
    || echo "${line}" | sudo tee -a "${file}"
}

#######################################
# Helper to append lines to _all_ the different shell files with single
# command currently bash and zsh, due Macs transition from bash to zsh as
# the default shell.
#
# In case the line needs a shell specific part there is %SHELL_NAME% macro
# that is replaced with the shell name (bash|zsh)
# Globals:
#   None
# Arguments:
#   text to append
#######################################
nipsulidotfiles::append_to_shell_files() {
  if [[ -z "${1}" ]]; then
    echo "Invalid usage, needs an argument: line to append to shell files"
    exit 1
  fi
  # touch ~/.bash_profile
  touch ~/.bashrc
  touch ~/.zshrc
  local shell_name="bash"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  # nipsulidotfiles::append_to_file ~/.bash_profile "${formated_str}"
  nipsulidotfiles::append_to_file ~/.bashrc "${formated_str}"
  local shell_name="zsh"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  nipsulidotfiles::append_to_file ~/.zshrc "${formated_str}"
}

#######################################
# END GENERIC HELPERS
#######################################

#######################################
# Ensure xcode commandline tools are installed
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::ensure_xcode_commandline_tools() {
  if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
    test -d "${xpath}" && test -x "${xpath}" ; then
    echo "xcode command line tools already installed!"
  else
    echo "Installing xcode command line tools"
    xcode-select --install
  fi
}


#######################################
# Ensure homebrew is installed WSL
# https://brew.sh
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_homebrew_wsl() {
  if type brew >&- ; then
    echo "brew already installed"
  else
    echo "Installing homebrew, this might take time, read more from
      https://brew.sh"
    /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_SCRIPT}")"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/nipsuli/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    sudo apt-get install build-essential
    # brew install gcc
  fi
}

#######################################
# Ensure homebrew is installed
# https://brew.sh
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_homebrew() {
  if type brew >&- ; then
    echo "brew already installed"
  else
    echo "Installing homebrew, this might take time, read more from
      https://brew.sh"
    /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_SCRIPT}")"
  fi
}

#######################################
# Install command line client for App Store and ensure one is logged in
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_appstore_cli() {
  brew install mas                        # Commandline tool for App Store
  # brew install mas-cli/tap/mas          # this is needed on older macs

  if mas account >&- ; then
      echo "You've logged in in app store"
  else
    read -n 1 -s -r -p "Need to login to AppStore manually, press any key to
      open App Store."
    echo
    open -a App\ Store
    read -n 1 -s -r -p "Press any key to continue."
    echo
  fi
}

#######################################
# Installs packagemangers for mac:
# * homebrew https://brew.sh
# * command client for App Store: mas
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_package_managers() {
  nipsulidotfiles::ensure_xcode_commandline_tools
  nipsulidotfiles:install_homebrew
  nipsulidotfiles::install_appstore_cli
}

#######################################
# Configures git and GitHub cli
# * GitHub client (gh)
# * adds ssh key to GitHub
# Globals:
#   EMAIL
# Arguments:
#   None
######################################
nipsulidotfiles::setup_git() {
  local keyid
  nipsulidotfiles::check_email_var
  git config --global user.email "${EMAIL}"
  ssh-keygen -t rsa -b 4096 -C "${EMAIL}"
  brew install gh
  gh auth login                   # This will also upload ssh key to GitHub
}

#######################################
# Configures git with gpg signing
# Globals:
#   EMAIL
# Arguments:
#   None
######################################
nipsulidotfiles::setup_git_commit_signing_mac() {
  brew install --cask gpg-suite
  gpg --quick-generate-key "<${EMAIL}>"
  read -n 1 -s -r -p "This will push the public gpg key to to clipboard and open
    GitHub for you to add the key. Press any key to continue"
  echo
  keyid=$(gpg --list-signatures --with-colons \
    | grep 'sig' \
    | grep "${EMAIL}" \
    | head -n 1 \
    | cut -d':' -f5)
  readonly keyid
  gpg --export -a "${keyid}" | pbcopy
  open https://github.com/settings/gpg/new
  read -n 1 -s -r -p "Continue after you've set up the key.
    Press any key to continue"
  echo
  git config --global user.signingkey "${keyid}"
  git config --global commit.gpgsign true
}

#######################################
# Configures alt + a/o to ä and ö
# At least in US key layout this overwrites ø and å
# This is personally preferred key mapping for those as I use US key layout but
# need to write Finnish often. And alt + key is more convenient than ¨ + a/o
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::setup_keybindings() {
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

#######################################
# Configure System Preferences
# Never configure stuff from GUI, store all settings here
# How to find correct setting path:
# https://pawelgrzybek.com/change-macos-user-preferences-via-command-line/
#
# Simplest way to find correct setting:
# 1. defaults read > before
# 2. toggle the setting in UI
# 3. defaults read > before
# 4. diff files
#
# These settings are sane defaults IMO, read the function body for every setting
# Most likely this is still missing some valuable settings
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_system_preferences() {
  # Who the hell thought that Desktop would be good location for screenshots?
  mkdir ~/Desktop/screenshots
  defaults write com.apple.screencapture location ~/Desktop/screenshots
  # Some sanity to finder, like showing also hidden files and full paths
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  # I don't like Apples default clock on the menu bar and and one cannot remove
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

  echo "restarting affected applications"
  killall SystemUIServer
  killall Finder
  killall Dock
}

#######################################
# Set default exports to shell files
# personally I like to have ${EMAIL} available
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::setup_basic_env() {
  nipsulidotfiles::check_email_var
  nipsulidotfiles::append_to_shell_files "export EMAIL=${EMAIL}"
}

#######################################
# Install tools that make command line experience better
#
# Tools to be installed:
# * exa, better looking ls
# * bat, better looking cat
# * fzf, rg and ag for search stuff
# * tty-clock, u know, why not ⊂(◉‿◉)つ
#
# check for more possible goodies:
# https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_commandline_tools_wsl() {
  # sudo apt install -y exa
  brew install exa
  sudo apt install -y bat
  sudo apt install -y fzf
  # sudo apt install -y ripgrep
  brew install ripgrep
  # sudo apt install -y the_silver_searcher
  brew install the_silver_searcher
  sudo apt install -y tty-clock
  sudo apt install -y jq
}

#######################################
# Install tools that make command line experience better
#
# Tools to be installed:
# * exa, better looking ls
# * bat, better looking cat
# * fzf, rg and ag for search stuff
# * tty-clock, u know, why not ⊂(◉‿◉)つ
# * lot of small utils, gnu versions from many of them
#
# check for more possible goodies:
# https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_commandline_tools() {
  brew install exa
  brew install bat
  brew install fzf
  "$(brew --prefix)"/opt/fzf/install
  brew install ripgrep
  brew install the_silver_searcher
  brew install tty-clock
  brew install jq
  brew install htop
  brew install watch
  brew install coreutils findutils
  brew install gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt
  brew install grep wget gzip
}

#######################################
# Link .bash_profile / .zsh
# Works with both bash and zsh
# This only adds linking and sourcing to the .bash_profile defined in this repo
# to keep the bash_profile clean here, as many app installation pushes all kinds
# of stuff to the .bash_profile / .zshrc
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::link_shell_profile() {
  ln -sf "${PWD}/dotfiles/.bash_profile" ~/.bash_profile_shared
  nipsulidotfiles::append_to_shell_files "source ~/.bash_profile_shared"
}

######################################
# Configure styling for console
# After everything I've tested so far I've settled with
# [starship](https://starship.rs). It's simple, fast and configurable, but the
# defaults are already spot on.
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_console_styles() {
  brew install starship
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(starship init %SHELL_NAME%)"'
}

######################################
# Starship requires [nerdfonts](https://www.nerdfonts.com) so installing two of
# my favourites: Hack and Fira-Code
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_fonts_mac() {
  brew tap homebrew/cask-fonts
  brew install --cask font-hack-nerd-font
  brew install --cask font-fira-code
  # TODO(@Nipsuli) On VSCode set terminal font family to Hack Nerd Font Mono
  # this should be automated as well
}

######################################
# Install python and friends
# * pyenv for managing environments
# * poetry for making dependency management nicer
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_python() {
  brew install python
  brew install pyenv
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'export PYENV_ROOT="$HOME/.pyenv"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'export PATH="$PYENV_ROOT/bin:$PATH"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(pyenv init --path)"'
  brew install poetry
}

######################################
# Install node and friends
# * nvm for managing node versions
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_node() {
  brew install nodejs
  brew install nvm
  mkdir -p ~/.nvm
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files \
    'export NVM_DIR="$HOME/.nvm"'
  nipsulidotfiles::append_to_shell_files \
    '[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"'
  nipsulidotfiles::append_to_shell_files \
    '[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"'
}

######################################
# Installs some languages and friends
# Even though one probably should run most of the stuff within containers having
# the languages locally can help e.g. with different auto completes
#
# ps. Deno is my favourite scripting environment
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_languages() {
  nipsulidotfiles::install_python
  nipsulidotfiles::install_node
  brew install deno
  brew install cmake
  # brew install mono
  # sudo apt install gnupg ca-certificates
  # sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
  # echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
  # sudo apt update
  # sudo apt install mono-devel
  brew install go
  brew install java
  # local flags=(
  #   /usr/local/opt/openjdk/libexec/openjdk.jdk
  #   /Library/Java/JavaVirtualMachines/openjdk.jdk
  # )
  # sudo ln -sfn "${flags[@]}"
  brew install julia
  brew install zig
  # brew install vlang
  # brew install ponyc
  brew install shellcheck # you will write shell scripts, at least check them
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

#######################################
# Install and configure Alacritty
# Alacritty is perhaps the best terminal emulator:
# 1. it's light and fast
# 2. you can configure it to basically disappear
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_alacrity() {
  brew install alacritty
  ln -sf "${PWD}/dotfiles/.alacritty.yml" ~/.alacritty.ym
}

#######################################
# Installs both vim and neovim
# So far I haven't seen any benefits from neovim but keeping it here untill I've
# evaluated it more
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_vim() {
  brew install vim
  brew install neovim
}

#######################################
# Configures vim
# * Plug as plugin manger
# * links vimrc
# * installs plugins
# * installs YouCompleteMe for autocompletion
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_vim() {
  # I prefer Plug as vim plugin manager
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  ln -sf "${PWD}/dotfiles/.vimrc" ~/.vimrc
  # make things work with neovim as well
  mkdir -p ~/.config/nvim/
  ln -sf "${PWD}/dotfiles/init.vim" ~/.config/nvim/init.vim

  vim +'PlugInstall --sync' +qa

  # Install YouCompleteMe
  # this one will require most of the stuff from
  # nipsulidotfiles::install_languages
  local curr_dir="${PWD}"
  cd ~/.vim/plugged/YouCompleteMe/
  python3 install.py --all
  cd "${curr_dir}"
}

#######################################
# Install tmux
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_tmux() {
  brew install tmux
  # this next was needed at least before for tmux copy, not 100% any more
  brew install reattach-to-user-namespace
}

#######################################
# Configures tmux
# * tpm for plugin manager
# * links .tmux.conf
# * installs plugins
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_tmux() {
  ln -sf "${PWD}/dotfiles/.tmux.conf" ~/.tmux.conf
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # shellcheck disable=SC2088
  tmux new -s install_session \
    '~/.tmux/plugins/tpm/tpm && ~/.tmux/plugins/tpm/bindings/install_plugins'
}

#######################################
# Install terminal tools and does configuratiosn to make terminal life enjoyable
# * Configures shell (bash/zsh)
# * alacritty, terminal emulator
# * vim (/neovim), preferred text editor
# * tmux, terminal multiplexer
# * + all kind of other goodies
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_terminal_wsl() {
  nipsulidotfiles::install_commandline_tools_wsl
  nipsulidotfiles::link_shell_profile
  nipsulidotfiles::configure_console_styles
  # nipsulidotfiles::install_languages # FIX ME: this requires some fixing
  # as YCM doesn't work, some tips from https://github.com/ycm-core/YouCompleteMe#linux-64-bit
  sudo apt install -y build-essential cmake vim-nox python3-dev
  sudo apt install -y mono-complete golang nodejs default-jdk npm
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  nipsulidotfiles::configure_vim
  nipsulidotfiles::configure_tmux
}

#######################################
# Install terminal tools and does configuratiosn to make terminal life enjoyable
# * Configures shell (bash/zsh)
# * alacritty, terminal emulator
# * vim (/neovim), preferred text editor
# * tmux, terminal multiplexer
# * + all kind of other goodies
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_terminal() {
  nipsulidotfiles::install_commandline_tools
  nipsulidotfiles::link_shell_profile
  nipsulidotfiles::configure_console_styles
  nipsulidotfiles::install_fonts_mac
  nipsulidotfiles::install_languages
  nipsulidotfiles::install_alacrity
  nipsulidotfiles::install_vim
  nipsulidotfiles::configure_vim
  nipsulidotfiles::install_tmux
  nipsulidotfiles::configure_tmux
}

######################################
# Install network and security related apps
# * WARP, not-VPN VPN for private and fast internet access
# * Private Internet Access, VPN, requires account
# * wireguard, generic VPN client
# * LastPass (including cli), Password manager
# * Little Snitch, Network monitoring tool
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_internet_security_apps() {
  brew install --cask cloudflare-warp
  brew install --cask private-internet-access
  mas install 1451685025                      # Wireguard
  mas install 926036361                       # LastPass
  # Note also https://github.com/lastpass/lastpass-cli/issues/604
  brew install lastpass-cli
  brew install --cask little-snitch
}

######################################
# Install all kind of utilities
# * Spotify
# * Rectangle, window manager
# * EasyRes, every once and while you'll need non standard resolutions
# * iStat Menus, system monitoring tool to menubar
# * Key Codes, useful when one needs the hex code of key combos
# * Ping Plotter, Don't you hate bad internet connection?
#                 Find where the bottleneck is with Ping Plotter!
#                 Visual ping + traceroute
# * Disk Inventory X, find what eats all the disk space!
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_utilities() {
  brew install --cask spotify
  brew install ncspot           # Commandline spotify for the true ppl
  brew install --cask rectangle # NOTE: could try https://emmetapp.com
  mas install 688211836         # EasyRes
  # mas purchase 1319778037     # iStat Menus,
                                # I've used the brew version and manual licence
                                # You probably should use the mas version
  brew install --cask istat-menus
  mas purchase 414568915        # Key Codes
  brew install --cask pingplotter
  brew install --cask disk-inventory-x
  brew install --cask xbar      # Could probs replace iStat Menus with this
}

######################################
# Install xbar plugins
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_xbar_plugins() {
  curl https://raw.githubusercontent.com/unixorn/lima-xbar-plugin/main/lima-plugin --output ~/Library/Application\ Support/xbar/plugins/lima-plugin.30s
  chmod +x ~/Library/Application\ Support/xbar/plugins/lima-plugin.30s
}

######################################
# Install productivity apps
# * Obsidian for notes
# * MS ToDo,  I used to use Wunderlist, but MS bought it,
#             and basically made ToDo from that.
# * Fantastical, best calendar. Period.
# * Spark, email app, highly recommend this one!
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_productivity_apps() {
  brew install --cask obsidian
  mas install 1274495053
  # mas purchase 975937182      # Fantastical,
                                # I've used the brew version and manual licence
                                # You probably should use the mas version
  brew install --cask fantastical
  mas install 1176895641        # Spark
}

######################################
# Install messenger apps
# * Slack
# * Telegram
# * Discord
#
# I've been trying to find good app to combine all the chats to one place but
# everything seems like shit ʕノ•ᴥ•ʔノ ︵ ┻━┻
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_messengers() {
  mas install 803453959         # Slack
  mas install 747648890         # Telegram
  brew install --cask discord   # For cool kids
}

######################################
# Install browsers
# * Vivaldi, my current favourite browser
# * Chrome, to isolate work accounts to own browser
# * Firefox, I feel this browser isn't getting enought love from users
# * Opera, what's a computer without Opera, perhaps my first browser crush
# * OperaGX, gamer needs a gaming browser
# * qutebrowser, keyboard focused minimal browser, just because
# I do like to compare different browsers. That's fun
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_browsers() {
  brew install --cask vivaldi
  brew install --cask google-chrome
  brew install --cask firefox
  brew install --cask opera
  brew install --cask opera-gx
  brew install --cask qutebrowser
  mas purchase 1480933944             # Vimari plugin for Safari
}

######################################
# Installs VSCode and extensions
# This does not contain all, VSCode is too sneaky to suggest installing from GUI
# TODO(@Nipsuli) should ensure all good extensions are on this list
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_vscode() {
  brew install visual-studio-code
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files \
    'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/
    Resources/app/bin"'
  code --install-extension iocave.customize-ui     # get rid of title bar
  code --install-extension VSCodeVim.Vim           # who doesn't want vim?
  code --install-extension bmalehorn.shell-syntax  # Yup yup, shell syntax
  code --install-extension timonwong.shellcheck    # + checking
}

######################################
# Installs GUI text editors
# * Sublime Text
# * VSCode
# One should use docker for all dev stuff and run nothing on local machine
# Even though everything is containered in 202X one might need VM's
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_gui_text_editors() {
  brew install sublime-text
  nipsulidotfiles::install_vscode
}

######################################
# Installs "virtualizations"
# * docker
# * virtualbox
# * direnv
# * dmg2img, helper to, well, convert dmg to "normal" disk image
#
# One should use docker for all dev stuff and run nothing on local machine.
# Even though everything is containered in 202X one might need VM's.
# [Direnv](https://direnv.net) allows you to scope environment variables to dir
# so including it to this list.
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_virtualizations() {
  brew install docker
  brew install virtualbox
  brew install direnv
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(direnv hook %SHELL_NAME%)"'
  brew install dmg2img
  brew install lima
}

######################################
# Install helper scripts
# Links all the scripts from ./scripts and adds command line cheatsheet
# https://github.com/chubin/cheat.sh
# to ~/bin
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_helper_scripts() {
  mkdir -p ~/bin
  ln -sf "${PWD}/scripts/mtwrfsu" ~/bin/mtwrfsu
  ln -sf "${PWD}/scripts/git-clean" ~/bin/git-clean
  # lpass cli is not enough, this fixes the missing parts
  ln -sf "${PWD}/scripts/lpass-copy" ~/bin/lpass-copy
  # command line cheat sheet
  curl https://cht.sh/:cht.sh > ~/bin/cht.sh
  chmod +x ~/bin/cht.sh
  brew install rlwrap
}

main() {
  echo "This is a helper module, nothing to execute here."
  exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
