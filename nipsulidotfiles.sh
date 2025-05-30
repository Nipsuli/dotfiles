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
#
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
#
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
#
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
  touch ~/.bash_profile
  touch ~/.zshrc
  local shell_name="bash"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  nipsulidotfiles::append_to_file ~/.bash_profile "${formated_str}"
  local shell_name="zsh"
  local formated_str=${1/\%SHELL_NAME\%/${shell_name}}
  nipsulidotfiles::append_to_file ~/.zshrc "${formated_str}"
}

#######################################
# END GENERIC HELPERS
#######################################

#######################################
# Ensure xcode commandline tools are installed
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::ensure_xcode_commandline_tools() {
  if xcode-select -p ; then
    echo "xcode command line tools already installed!"
  else
    echo "Installing xcode command line tools"
    xcode-select --install
  fi
}

#######################################
# Ensure homebrew is installed
#
# https://brew.sh
#
# Globals:
#   BREW_INSTALL_SCRIPT
# Arguments:
#   None
######################################
nipsulidotfiles::install_homebrew() {
  if type brew >&- ; then
    echo "brew already installed"
  else
    echo "Installing homebrew, this might take time, read more from
      https://brew.sh"
    # shellcheck disable=SC2312
    /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_SCRIPT}")"
    # shellcheck disable=SC2016
    nipsulidotfiles::append_to_shell_files 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    evalcommand="$(/opt/homebrew/bin/brew shellenv)"
    eval "${evalcommand}"
  fi
}

#######################################
# Install command line client for App Store and ensure one is logged in
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_appstore_cli() {
  brew install mas                        # Commandline tool for App Store

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
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_package_managers() {
  nipsulidotfiles::install_appstore_cli
  nipsulidotfiles::ensure_xcode_commandline_tools
  nipsulidotfiles::install_homebrew
}

#######################################
# Configures git and GitHub cli
# * git with gpg signing
# * GitHub client (gh)
# * adds ssh key to GitHub
#
# Globals:
#   EMAIL
# Arguments:
#   None
######################################
nipsulidotfiles::setup_git() {
  local keyid
  nipsulidotfiles::check_email_var
  git config --global user.email "${EMAIL}"
  git config --global pull.rebase false
  ssh-keygen -t rsa -b 4096 -C "${EMAIL}" || true # allow not overwriting
  brew install gh
  gh auth login                   # This will also upload ssh key to GitHub
  brew install --cask gpg-suite
  gpg --quick-generate-key "<${EMAIL}>"
  read -n 1 -s -r -p "This will push the public gpg key to to clipboard and open
    GitHub for you to add the key. Press any key to continue"
  echo
  # shellcheck disable=SC2312
  keyid=$(gpg --list-signatures --with-colons \
    | grep 'sig' \
    | grep "${EMAIL}" \
    | head -n 1 \
    | cut -d':' -f5)
  readonly keyid
  # shellcheck disable=SC2312
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
#
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
    "~a" = "(insertText:, "ä")";
    "~o" = "(insertText:, "ö")";
    "~A" = "(insertText:, "Ä")";
    "~O" = "(insertText:, "Ö")";
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
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::configure_system_preferences() {
  # Who the hell thought that Desktop would be good location for screenshots?
  mkdir -p ~/Desktop/screenshots
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
  # make caps to esc
  defaults write com.apple.keyboard.modifiermapping.1452-834-0 '(
    {
      HIDKeyboardModifierMappingDst = 30064771113;
      HIDKeyboardModifierMappingSrc = 30064771129;
    }
  )'

  # Hide dock to right so it won't take half of the screen
  defaults write com.apple.dock autohide -int 1
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
#
# Globals:
#   EMAIL
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
# * eza, better looking ls (maintained fork of exa)
# * bat, better looking cat
# * fzf, rg and ag for search stuff
# * tty-clock, u know, why not ⊂(◉‿◉)つ
# * lot of small utils, gnu versions from many of them
#
# check for more possible goodies:
# https://dev.to/_darrenburns/10-tools-to-power-up-your-command-line-4id4
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_commandline_tools() {
  brew install eza
  brew install bat
  brew install fzf
  "$(brew --prefix)"/opt/fzf/install
  brew install ripgrep
  brew install the_silver_searcher
  brew install tty-clock
  brew install jq
  brew install htop
  brew install btop
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
  ln -sf "${PWD}/dotfiles/.nipsuli_profile" ~/.nipsuli_profile
  nipsulidotfiles::append_to_shell_files "source ~/.nipsuli_profile"
}

######################################
# Configure styling for console
# After everything I've tested so far I've settled with
# [starship](https://starship.rs). It's simple, fast and configurable, but the
# defaults are already spot on.
#
# Starship requires [nerdfonts](https://www.nerdfonts.com) so installing two of
# my favourites: Hack and Fira-Code
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
  brew tap homebrew/cask-fonts
  brew install --cask font-hack-nerd-font
  brew install --cask font-fira-code
}

######################################
# Install python and friends
# * uv as the new kid in the block
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_python() {
  # uv is "A single tool to replace pip, pip-tools, pipx, poetry, pyenv, twine, virtualenv, and more."
  brew install uv
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(uv generate-shell-completion %SHELL_NAME%)"'
  uv python install install 3.12
}

######################################
# Install lisp
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_lisp() {
  brew install sbcl
  curl -O https://beta.quicklisp.org/quicklisp.lisp.asc
  # figure out automation for
  # do
  # sbcl --load quicklisp.lisp
  # (quicklisp-quickstart:install)
  # (exit)
}

######################################
# Install node
# use fnm as the fast node managoer
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_node() {
  brew install fnm
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(fnm env --use-on-cd --shell %SHELL_NAME%)"'
  fnm completions --shell bash
  fnm completions --shell zsh

  fnm install 23
  fnm default 23

  # needed for nvim stuff
  brew install fsouza/prettierd/prettierd
  npm install -g eslint_d
}

######################################
# Installs some languages and friends
# Even though one probably should run most of the stuff within containers having
# the languages locally can help e.g. with different auto completes
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_languages() {
  nipsulidotfiles::install_python
  nipsulidotfiles::install_node

  brew install go
  brew install deno
  # brew install cmake
  # brew install mono
  #
  # brew install java
  # local flags=(
  #   /usr/local/opt/openjdk/libexec/openjdk.jdk
  #   /Library/Java/JavaVirtualMachines/openjdk.jdk
  # )
  # sudo ln -sfn "${flags[@]}"
  #
  # brew install julia
  # brew install zig
  brew install shellcheck          # you will write shell scripts, at least check them
  # shellcheck disable=SC2312
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  nipsulidotfiles::install_lisp
}

#######################################
# Install and configure Wezterm
# Used to run Alacritty, but Wezterm ended up being better
# No evaluating ghostty as an alternative
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_terminalemulators() {
  brew install --cask wezterm
  ln -sf "${PWD}/dotfiles/.wezterm.lua" ~/.wezterm.lua
  brew install --cask ghostty
  mkdir -p ~/.config/ghostty
  ln -sf "${PWD}/dotfiles/ghostty_config" ~/.config/ghostty/config
}


#######################################
# Install and configures vim
#
# Classic vim still as backup even though neovim is way better for all the suff
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_vim() {
  brew install vim
  # I prefer Plug as vim plugin manager
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  ln -sf "${PWD}/dotfiles/.vimrc" ~/.vimrc
  vim +'PlugInstall --sync' +qa

  # This would take ages, and as vim is not anymore main editor, not doing it
  # keeping it here as a reference
  # Install YouCompleteMe
  # this one will require most of the stuff from
  # nipsulidotfiles::install_languages
  # local curr_dir="${PWD}"
  # cd ~/.vim/plugged/YouCompleteMe/
  # python3 install.py --all
  # cd "${curr_dir}"

  # CosmicNvim requires pre-release
  brew install neovim --HEAD
  mkdir -p ~/.config/nvim/
  # OLD CONF ln -sf "${PWD}/dotfiles/init.vim" ~/.config/nvim/init.vim
  # Install CosmicNvim
  # Currently test driving CosmicNvim
  cd ~/.config
  git clone git@github.com:CosmicNvim/CosmicNvim.git nvim
  ln -sf "${PWD}/dotfiles/cosmic/config.lua" ~/.config/nvim/lua/cosmic/config/
  ln -sf "${PWD}/dotfiles/cosmic/editor.lua" ~/.config/nvim/lua/cosmic/config/
  # CosmicNvim installs all the stuff
  nvim --headless +qa
  # trigger copilot install
  nvim --headless +Copilot setup +q

}

#######################################
# Install and configures tmux
# * tpm for plugin manager
# * links .tmux.conf
# * installs plugins
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_tmux() {
  brew install tmux
  # this next was needed at least before for tmux copy, not 100% any more
  brew install reattach-to-user-namespace
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
nipsulidotfiles::configure_terminal() {
  nipsulidotfiles::install_commandline_tools
  nipsulidotfiles::link_shell_profile
  nipsulidotfiles::configure_console_styles
  nipsulidotfiles::install_languages
  nipsulidotfiles::install_terminalemulators
  nipsulidotfiles::install_vim
  nipsulidotfiles::install_tmux
}

######################################
# Install network and security related apps
# * WARP, not-VPN VPN for private and fast internet access
# * Private Internet Access, VPN, requires account
# * wireguard, generic VPN client
# * LastPass (including cli), Password manager
# * Little Snitch, Network monitoring tool
#
# Globals:
#   None
# Arguments:
#   None
######################################
nipsulidotfiles::install_internet_security_apps() {
  brew install --cask cloudflare-warp
  # brew install --cask private-internet-access
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
#
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_utilities() {
  brew install --cask spotify
  brew install ncspot           # Commandline spotify for the true ppl
  # brew install --cask rectangle # NOTE: could try https://emmetapp.com
  brew install --cask istat-menus
  brew install --cask pingplotter
  brew install --cask disk-inventory-x
  brew install --cask raycast
  brew install --cask idrive
  # brew install --cask xbar      # Could probs replace iStat Menus with this
  brew install hstr             # command history searcher
  # https://github.com/yorukot/superfile
  bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
}

######################################
# Install xbar plugins
# Globals:
#   None
# Arguments:
#   None
#####################################
# nipsulidotfiles::install_xbar_plugins() {
#   curl https://raw.githubusercontent.com/unixorn/lima-xbar-plugin/main/lima-plugin --output ~/Library/Application\ Support/xbar/plugins/lima-plugin.30s
#   chmod +x ~/Library/Application\ Support/xbar/plugins/lima-plugin.30s
# }

######################################
# Install productivity apps
# * Obsidian for notes
# * MS ToDo,  I used to use Wunderlist, but MS bought it,
#             and basically made ToDo from that.
# * Fantastical, best calendar. Period.
# * Spark, email app, highly recommend this one!
#
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_productivity_apps() {
  # brew install --cask obsidian
  # mas install 1274495053
  # mas install 975937182       # Fantastical,
                                # I've used the brew version and manual licence
                                # You probably should use the mas version
  # brew install --cask fantastical
  mas install 1176895641        # Spark
  # brew install --cask shottr    # Screenshot app
}

######################################
# Install messenger apps
# * Slack
# * Telegram
# * Discord
#
# I've been trying to find good app to combine all the chats to one place but
# everything seems like shit ʕノ•ᴥ•ʔノ ︵ ┻━┻
#
# Globals:
#   None
# Arguments:
#   None
#####################################
nipsulidotfiles::install_messengers() {
  mas install 803453959         # Slack
  # mas install 747648890         # Telegram
  brew install --cask discord   # For cool kids
}

######################################
# Install Firefox
# Configures also the minimalistic theme
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_firefox() {
  brew install --cask firefox
  mkdir -p ~/code
  git clone git@github.com:andreasgrafen/cascade.git ~/code/cascade
  local ffbasedir="$(echo /Users/"${USER}"/Library/Application\ Support/Firefox/Profiles/*.default-*)"
  mkdir -p "${ffbasedir}/chrome/includes"
  local userChromeFileName="${ffbasedir}/chrome/userChrome.css"
  if [ -f "$userCrhomeFilename"] ; then
    rm "$userChromeFileName"
  fi
  ln -s "/Users/${USER}/code/cascade/chrome/userChrome.css" ${userChromeFileName}

  local includesBase="/Users/${USER}/code/cascade/chrome/includes"

  for item in "${includesBase}"/*; do
    if [ -f "$item" ]; then
      targetFile="${ffbasedir}/chrome/includes/$(basename "$item")"
      if [ -f "$targetFile" ] ; then
        rm "$targetFile"
      fi
      ln -s "$item" "$targetFile"
    fi
  done
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
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_browsers() {
  brew install --cask vivaldi
  brew install --cask google-chrome
  brew install --cask zen-browser
  # nipsulidotfiles::install_firefox
  # brew install --cask opera
  # brew install --cask opera-gx
  # brew install --cask qutebrowser
  # mas install 1480933944             # Vimari plugin for Safari
}

######################################
# Installs VSCode and extensions
# This does not contain all, VSCode is too sneaky to suggest installing from GUI
# TODO(@Nipsuli) should ensure all good extensions are on this list
#
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
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_gui_text_editors() {
  brew install sublime-text
  # nipsulidotfiles::install_vscode
  brew install --cask zed@preview
}

######################################
# Installs "virtualizations"
# * docker
# * virtualbox
# * direnv
# * lima and colima
# * tart
# * dmg2img, helper to, well, convert dmg to "normal" disk image
#
# One should use docker for all dev stuff and run nothing on local machine.
# Even though everything is containered in 202X one might need VM's.
# [Direnv](https://direnv.net) allows you to scope environment variables to dir
# so including it to this list.
#
# Tart is nice for OSX virtualization https://tart.run/quick-start/#
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_virtualizations() {
  brew install docker
  # brew install virtualbox
  brew install direnv
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(direnv hook %SHELL_NAME%)"'
  brew install dmg2img
  brew install lima
  brew install colima
  brew install cirruslabs/cli/tart
}

######################################
# Install helper scripts
# Links all the scripts from ./scripts and adds command line cheatsheet
# https://github.com/chubin/cheat.sh
# to ~/bin
#
# Globals:
#   None
# Arguments:
#   None
####################################
nipsulidotfiles::install_helper_scripts() {
  mkdir -p ~/bin
  ln -sf "${PWD}/scripts/mtwrfsu" ~/bin/mtwrfsu
  ln -sf "${PWD}/scripts/git-clean" ~/bin/git-clean
  # command line cheat sheet
  curl https://cht.sh/:cht.sh > ~/bin/cht.sh
  chmod +x ~/bin/cht.sh
  brew install rlwrap
  brew install mutagen-io/mutagen/mutagen
}

main() {
  echo "This is a helper module, nothing to execute here."
  exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

######################################
# remind about manual installations
####################################
nipsulidotfiles::remind_manual_installations() {
  echo "Remember check manually"
  # from lisp installation, could think if can be automated
  echo "# do\n# sbcl --load quicklisp.lisp\n# (quicklisp-quickstart:install)\n# (exit)"
  # ditching yabai
  # echo "  - yabai SIP https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"
  # echo "  - yabai SA https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition"
}
