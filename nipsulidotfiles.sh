#!/bin/bash
# shellcheck disable=SC2310,SC2311,SC2312,SC2249
#######################################
# Helper functions for the Mac setup orchestrator.
#######################################
set -e

readonly BREW_INSTALL_SCRIPT="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly TIGRISFS_LATEST_RELEASE_URL="https://github.com/tigrisdata/tigrisfs/releases/latest"
readonly TIGRISFS_DOWNLOAD_BASE_URL="https://github.com/tigrisdata/tigrisfs/releases/download"

NIPSULI_DOTFILES_ROOT="${NIPSULI_DOTFILES_ROOT:-$(pwd)}"
NIPSULI_BREWFILES_DIR="${NIPSULI_DOTFILES_ROOT}/brewfiles"

readonly COLOR_RESET='\033[0m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_CYAN='\033[0;36m'

nipsulidotfiles::log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

nipsulidotfiles::log_success() {
  echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

nipsulidotfiles::log_warn() {
  echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

nipsulidotfiles::log_error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

nipsulidotfiles::log_section() {
  echo -e "\n${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
  echo -e "${COLOR_CYAN}▶ $1${COLOR_RESET}"
  echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n"
}

nipsulidotfiles::check_email_var() {
  if [[ -z "${EMAIL:=}" ]]; then
    nipsulidotfiles::log_error "No EMAIL environment variable available."
    exit 1
  fi
}

nipsulidotfiles::append_to_file() {
  if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
    nipsulidotfiles::log_error "Invalid usage, needs filepath and line."
    exit 1
  fi

  local file="$1"
  local line="$2"
  touch "${file}"
  grep -qF -- "${line}" "${file}" || printf '%s\n' "${line}" >> "${file}"
}

nipsulidotfiles::append_to_shell_files() {
  if [[ -z "${1}" ]]; then
    nipsulidotfiles::log_error "Invalid usage, needs a line to append."
    exit 1
  fi

  local line_template="$1"
  local shell_name
  local formatted_line

  shell_name="bash"
  formatted_line="${line_template//%SHELL_NAME%/${shell_name}}"
  nipsulidotfiles::append_to_file "${HOME}/.bash_profile" "${formatted_line}"

  shell_name="zsh"
  formatted_line="${line_template//%SHELL_NAME%/${shell_name}}"
  nipsulidotfiles::append_to_file "${HOME}/.zshrc" "${formatted_line}"
}

nipsulidotfiles::git_clone_if_missing() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "${target_dir}" ]]; then
    nipsulidotfiles::log_warn "Directory ${target_dir} already exists, skipping clone."
  else
    nipsulidotfiles::log_info "Cloning ${repo_url} to ${target_dir}"
    git clone "${repo_url}" "${target_dir}"
  fi
}

nipsulidotfiles::require_known_profile() {
  case "$1" in
    core|cli|terminal|languages|apps|mas|virtualization|cloud)
      return 0
      ;;
    *)
      nipsulidotfiles::log_error "Unknown profile: $1"
      exit 1
      ;;
  esac
}

nipsulidotfiles::brewfile_for_profile() {
  nipsulidotfiles::require_known_profile "$1"
  printf '%s/Brewfile.%s\n' "${NIPSULI_BREWFILES_DIR}" "$1"
}

nipsulidotfiles::ensure_xcode_commandline_tools() {
  nipsulidotfiles::log_info "Checking Xcode command line tools..."
  if xcode-select -p >/dev/null 2>&1; then
    nipsulidotfiles::log_success "Xcode command line tools already installed."
  else
    nipsulidotfiles::log_info "Installing Xcode command line tools."
    xcode-select --install
  fi
}

nipsulidotfiles::install_homebrew() {
  local brew_shellenv

  nipsulidotfiles::log_info "Checking Homebrew..."
  if type brew >/dev/null 2>&1; then
    nipsulidotfiles::log_success "Homebrew already installed."
  else
    nipsulidotfiles::log_info "Installing Homebrew. This might take time."
    # shellcheck disable=SC2312
    /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_SCRIPT}")"
    # shellcheck disable=SC2016
    nipsulidotfiles::append_to_shell_files 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    brew_shellenv="$(/opt/homebrew/bin/brew shellenv)"
    eval "${brew_shellenv}"
  fi
}

nipsulidotfiles::bootstrap_package_managers() {
  nipsulidotfiles::log_section "Bootstrapping Package Managers"
  nipsulidotfiles::ensure_xcode_commandline_tools
  nipsulidotfiles::install_homebrew
}

nipsulidotfiles::install_profile() {
  local profile="$1"
  local brewfile

  brewfile="$(nipsulidotfiles::brewfile_for_profile "${profile}")"
  nipsulidotfiles::log_section "Installing ${profile}"

  if [[ "${profile}" == "mas" ]]; then
    nipsulidotfiles::ensure_mas_login
  fi

  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file "${brewfile}"
  nipsulidotfiles::configure_profile "${profile}"
}

nipsulidotfiles::dry_run_profile() {
  local profile="$1"
  local brewfile

  brewfile="$(nipsulidotfiles::brewfile_for_profile "${profile}")"
  nipsulidotfiles::log_section "Dry run ${profile}"
  nipsulidotfiles::log_info "Checking ${brewfile}"

  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "${brewfile}"; then
    nipsulidotfiles::log_success "All Brewfile entries for ${profile} are installed."
  else
    nipsulidotfiles::log_warn "Missing Brewfile entries listed above."
  fi

  nipsulidotfiles::print_profile_config_actions "${profile}"
}

nipsulidotfiles::list_profile() {
  local profile="$1"
  local brewfile

  brewfile="$(nipsulidotfiles::brewfile_for_profile "${profile}")"
  nipsulidotfiles::log_section "Listing ${profile}"
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file "${brewfile}"
  nipsulidotfiles::print_profile_config_actions "${profile}"
}

nipsulidotfiles::configure_profile() {
  case "$1" in
    core)
      nipsulidotfiles::configure_core
      ;;
    cli)
      nipsulidotfiles::configure_cli
      ;;
    terminal)
      nipsulidotfiles::configure_terminal
      ;;
    languages)
      nipsulidotfiles::configure_languages
      ;;
    apps)
      nipsulidotfiles::configure_apps
      ;;
    mas)
      nipsulidotfiles::configure_mas
      ;;
    virtualization)
      nipsulidotfiles::configure_virtualization
      ;;
    cloud)
      nipsulidotfiles::configure_cloud
      ;;
  esac
}

nipsulidotfiles::print_profile_config_actions() {
  nipsulidotfiles::log_info "Post-install configuration actions:"
  case "$1" in
    core)
      cat <<'EOF'
  - configure EMAIL, shell profile, starship, direnv, git, GPG, keybindings, and macOS defaults
EOF
      ;;
    cli)
      cat <<'EOF'
  - link helper scripts into ~/bin and install cht.sh
  - enable fzf shell completions/keybindings without changing shell rc files directly
EOF
      ;;
    terminal)
      cat <<'EOF'
  - link Ghostty, Vim, tmux, and CosmicNvim config
  - install vim-plug and tmux plugins
  - bootstrap CosmicNvim headlessly
EOF
      ;;
    languages)
      cat <<'EOF'
  - configure uv, fnm, Bun, Rust, Clojure, and shell hooks
  - install Node 24 through fnm
  - install Python 3.14 through uv
EOF
      ;;
    apps)
      cat <<'EOF'
  - link Zed settings and keymap
EOF
      ;;
    mas)
      cat <<'EOF'
  - verify the App Store account is available before mas installs
EOF
      ;;
    virtualization)
      cat <<'EOF'
  - verify Docker CLI and Colima are present
EOF
      ;;
    cloud)
      cat <<'EOF'
  - install TigrisFS into ~/bin if missing
  - remove the Tigris-provided t3 shim when it points at the Tigris CLI
  - leave Tigris credentials and mounts for manual setup
EOF
      ;;
  esac
}

nipsulidotfiles::configure_core() {
  nipsulidotfiles::log_info "Configuring core system settings..."
  nipsulidotfiles::setup_basic_env
  nipsulidotfiles::link_shell_profile
  nipsulidotfiles::configure_console_styles
  nipsulidotfiles::configure_direnv
  nipsulidotfiles::setup_git
  nipsulidotfiles::setup_keybindings
  nipsulidotfiles::configure_system_preferences
  nipsulidotfiles::log_success "Core configuration complete."
}

nipsulidotfiles::setup_basic_env() {
  nipsulidotfiles::check_email_var
  nipsulidotfiles::append_to_shell_files "export EMAIL=${EMAIL}"
}

nipsulidotfiles::link_shell_profile() {
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/.nipsuli_profile" "${HOME}/.nipsuli_profile"
  nipsulidotfiles::append_to_shell_files "source ~/.nipsuli_profile"
}

nipsulidotfiles::configure_console_styles() {
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(starship init %SHELL_NAME%)"'
}

nipsulidotfiles::configure_direnv() {
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(direnv hook %SHELL_NAME%)"'
}

nipsulidotfiles::setup_git() {
  local keyid

  nipsulidotfiles::check_email_var
  git config --global user.email "${EMAIL}"
  git config --global pull.rebase false

  if [[ ! -f "${HOME}/.ssh/id_ed25519.pub" ]]; then
    nipsulidotfiles::log_info "Creating default ed25519 SSH key."
    ssh-keygen -t ed25519 -C "${EMAIL}" -f "${HOME}/.ssh/id_ed25519" -N ""
  fi

  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      nipsulidotfiles::log_success "GitHub CLI already authenticated."
    else
      nipsulidotfiles::log_warn "GitHub CLI is not authenticated; starting gh auth login."
      gh auth login
    fi
  fi

  if command -v gpg >/dev/null 2>&1; then
    keyid="$(gpg --list-secret-keys --with-colons "${EMAIL}" 2>/dev/null \
      | awk -F: '/^sec:/ { print $5; exit }' || true)"

    if [[ -z "${keyid}" ]]; then
      nipsulidotfiles::log_info "Generating GPG key for ${EMAIL}."
      gpg --quick-generate-key "<${EMAIL}>"
      keyid="$(gpg --list-secret-keys --with-colons "${EMAIL}" \
        | awk -F: '/^sec:/ { print $5; exit }' || true)"
      if [[ -n "${keyid}" ]]; then
        gpg --export -a "${keyid}" | pbcopy || true
        nipsulidotfiles::log_warn "New GPG public key copied to clipboard; add it to GitHub manually."
      fi
    fi

    if [[ -n "${keyid}" ]]; then
      git config --global user.signingkey "${keyid}"
      git config --global commit.gpgsign true
    fi
  fi
}

nipsulidotfiles::setup_keybindings() {
  nipsulidotfiles::log_info "Configuring Finnish character shortcuts."
  mkdir -p "${HOME}/Library/KeyBindings"
  cat > "${HOME}/Library/KeyBindings/DefaultKeyBinding.dict" <<'EOF'
{
    "~a" = "(insertText:, \"ä\")";
    "~o" = "(insertText:, \"ö\")";
    "~A" = "(insertText:, \"Ä\")";
    "~O" = "(insertText:, \"Ö\")";
}
EOF
}

nipsulidotfiles::configure_system_preferences() {
  nipsulidotfiles::log_info "Configuring macOS defaults."
  mkdir -p "${HOME}/Desktop/screenshots"
  defaults write com.apple.screencapture location "${HOME}/Desktop/screenshots"
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.menuextra.clock IsAnalog -bool true
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write com.apple.keyboard.modifiermapping.1452-834-0 '(
    {
      HIDKeyboardModifierMappingDst = 30064771113;
      HIDKeyboardModifierMappingSrc = 30064771129;
    }
  )'
  defaults write com.apple.dock autohide -int 1
  defaults write com.apple.dock orientation right
  defaults write com.apple.dock tilesize -int 16

  killall SystemUIServer >/dev/null 2>&1 || true
  killall Finder >/dev/null 2>&1 || true
  killall Dock >/dev/null 2>&1 || true
}

nipsulidotfiles::configure_cli() {
  nipsulidotfiles::log_info "Configuring CLI helpers..."
  nipsulidotfiles::configure_fzf
  nipsulidotfiles::install_helper_scripts
  nipsulidotfiles::log_success "CLI configuration complete."
}

nipsulidotfiles::configure_fzf() {
  local fzf_install

  fzf_install="$(brew --prefix)/opt/fzf/install"
  if [[ -x "${fzf_install}" ]]; then
    "${fzf_install}" --key-bindings --completion --no-update-rc
  fi
}

nipsulidotfiles::install_helper_scripts() {
  local script

  mkdir -p "${HOME}/bin"
  for script in "${NIPSULI_DOTFILES_ROOT}"/scripts/*; do
    if [[ -f "${script}" ]]; then
      ln -sf "${script}" "${HOME}/bin/$(basename "${script}")"
    fi
  done

  curl -fsSL https://cht.sh/:cht.sh > "${HOME}/bin/cht.sh"
  chmod +x "${HOME}/bin/cht.sh"
}

nipsulidotfiles::configure_terminal() {
  nipsulidotfiles::log_info "Configuring terminal/editor stack..."
  nipsulidotfiles::configure_ghostty
  nipsulidotfiles::configure_vim
  nipsulidotfiles::configure_neovim
  nipsulidotfiles::configure_tmux
  nipsulidotfiles::log_success "Terminal configuration complete."
}

nipsulidotfiles::configure_ghostty() {
  mkdir -p "${HOME}/.config/ghostty"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/ghostty_config" "${HOME}/.config/ghostty/config"
}

nipsulidotfiles::configure_vim() {
  mkdir -p "${HOME}/.vim/autoload"
  if [[ ! -f "${HOME}/.vim/autoload/plug.vim" ]]; then
    curl -fLo "${HOME}/.vim/autoload/plug.vim" \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/.vimrc" "${HOME}/.vimrc"
  if command -v vim >/dev/null 2>&1; then
    vim +'PlugInstall --sync' +qa || nipsulidotfiles::log_warn "vim-plug install did not finish cleanly."
  fi
}

nipsulidotfiles::configure_neovim() {
  mkdir -p "${HOME}/.config"
  nipsulidotfiles::git_clone_if_missing "https://github.com/CosmicNvim/CosmicNvim.git" "${HOME}/.config/nvim"
  mkdir -p "${HOME}/.config/nvim/lua/cosmic/config"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/cosmic/config.lua" "${HOME}/.config/nvim/lua/cosmic/config/config.lua"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/cosmic/editor.lua" "${HOME}/.config/nvim/lua/cosmic/config/editor.lua"

  if command -v nvim >/dev/null 2>&1; then
    nvim --headless +qa || nipsulidotfiles::log_warn "CosmicNvim bootstrap did not finish cleanly."
  fi
}

nipsulidotfiles::configure_tmux() {
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/.tmux.conf" "${HOME}/.tmux.conf"
  nipsulidotfiles::git_clone_if_missing "https://github.com/tmux-plugins/tpm" "${HOME}/.tmux/plugins/tpm"

  if [[ -x "${HOME}/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    "${HOME}/.tmux/plugins/tpm/bin/install_plugins" || true
  fi
}

nipsulidotfiles::configure_languages() {
  nipsulidotfiles::log_info "Configuring programming language tools..."
  nipsulidotfiles::configure_uv
  nipsulidotfiles::configure_node
  nipsulidotfiles::configure_bun
  nipsulidotfiles::configure_rust
  nipsulidotfiles::log_success "Language configuration complete."
}

nipsulidotfiles::configure_uv() {
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(uv generate-shell-completion %SHELL_NAME%)"'
  if command -v uv >/dev/null 2>&1; then
    uv python install 3.14 || nipsulidotfiles::log_warn "uv Python install did not finish cleanly."
  fi
}

nipsulidotfiles::configure_node() {
  local fnm_env

  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(fnm env --use-on-cd --shell %SHELL_NAME%)"'

  if command -v fnm >/dev/null 2>&1; then
    fnm_env="$(fnm env --shell bash)"
    eval "${fnm_env}"
    fnm install 24
    fnm default 24
    corepack enable || true
  fi
}

nipsulidotfiles::configure_bun() {
  if ! command -v bun >/dev/null 2>&1; then
    nipsulidotfiles::log_info "Installing Bun."
    # shellcheck disable=SC2312
    curl -fsSL https://bun.sh/install | bash
  fi

  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_file "${HOME}/.zshrc" 'export BUN_INSTALL="$HOME/.bun"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_file "${HOME}/.zshrc" 'export PATH="$BUN_INSTALL/bin:$PATH"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_file "${HOME}/.zshrc" '[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"'
}

nipsulidotfiles::configure_rust() {
  if ! command -v rustup >/dev/null 2>&1; then
    nipsulidotfiles::log_info "Installing Rust through rustup."
    # shellcheck disable=SC2312
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files '. "$HOME/.cargo/env"'
}

nipsulidotfiles::configure_apps() {
  nipsulidotfiles::log_info "Configuring GUI app dotfiles..."
  mkdir -p "${HOME}/.config/zed"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/zed/settings.json" "${HOME}/.config/zed/settings.json"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/zed/keymap.json" "${HOME}/.config/zed/keymap.json"
  nipsulidotfiles::log_success "App configuration complete."
}

nipsulidotfiles::ensure_mas_login() {
  if ! command -v mas >/dev/null 2>&1; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install mas
  fi

  if mas account >/dev/null 2>&1; then
    nipsulidotfiles::log_success "App Store CLI is authenticated."
  else
    nipsulidotfiles::log_warn "Log into the App Store before MAS installs continue."
    open -a "App Store"
    read -r -n 1 -p "Press any key after signing into the App Store..."
    echo
  fi
}

nipsulidotfiles::configure_mas() {
  nipsulidotfiles::log_success "MAS apps installed. Xcode is included for the full GUI app."
}

nipsulidotfiles::configure_virtualization() {
  nipsulidotfiles::log_info "Configuring virtualization tools..."
  if command -v colima >/dev/null 2>&1; then
    nipsulidotfiles::log_warn "Run 'colima start' when you want to start the Docker runtime."
  fi
}

nipsulidotfiles::configure_cloud() {
  nipsulidotfiles::log_info "Configuring cloud tools..."
  nipsulidotfiles::remove_tigris_t3_shim
  nipsulidotfiles::install_tigrisfs
  nipsulidotfiles::log_warn "Tigris credentials and bucket mounts are intentionally manual."
}

nipsulidotfiles::remove_tigris_t3_shim() {
  local t3_path
  local t3_target

  if ! command -v t3 >/dev/null 2>&1; then
    return 0
  fi

  t3_path="$(command -v t3)"
  t3_target="$(readlink "${t3_path}" || true)"

  case "${t3_path} ${t3_target}" in
    *tigris*|*Tigris*)
      nipsulidotfiles::log_warn "Removing Tigris-provided t3 shim at ${t3_path}."
      rm -f "${t3_path}"
      ;;
    *)
      nipsulidotfiles::log_warn "Leaving existing t3 command alone: ${t3_path}"
      ;;
  esac
}

nipsulidotfiles::install_tigrisfs() {
  local arch
  local current_arch
  local latest_url
  local version
  local archive_name
  local archive_url
  local checksum_url
  local tmpdir
  local expected_checksum
  local actual_checksum
  local binary_path

  if command -v tigrisfs >/dev/null 2>&1; then
    nipsulidotfiles::log_success "tigrisfs already installed."
    return 0
  fi

  current_arch="$(uname -m)"
  case "${current_arch}" in
    arm64|aarch64)
      arch="arm64"
      ;;
    x86_64|amd64)
      arch="amd64"
      ;;
    *)
      nipsulidotfiles::log_error "Unsupported architecture for tigrisfs: ${current_arch}"
      return 1
      ;;
  esac

  latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "${TIGRISFS_LATEST_RELEASE_URL}")"
  version="${latest_url##*/}"
  version="${version#v}"
  archive_name="tigrisfs_${version}_darwin_${arch}.tar.gz"
  archive_url="${TIGRISFS_DOWNLOAD_BASE_URL}/v${version}/${archive_name}"
  checksum_url="${TIGRISFS_DOWNLOAD_BASE_URL}/v${version}/checksums.txt"
  tmpdir="$(mktemp -d)"

  curl -fsSL "${archive_url}" -o "${tmpdir}/${archive_name}"
  curl -fsSL "${checksum_url}" -o "${tmpdir}/checksums.txt"

  expected_checksum="$(grep " ${archive_name}$" "${tmpdir}/checksums.txt" | awk '{ print $1 }')"
  actual_checksum="$(shasum -a 256 "${tmpdir}/${archive_name}" | awk '{ print $1 }')"

  if [[ -z "${expected_checksum}" ]] || [[ "${expected_checksum}" != "${actual_checksum}" ]]; then
    nipsulidotfiles::log_error "Checksum verification failed for ${archive_name}."
    rm -rf "${tmpdir}"
    return 1
  fi

  tar -xzf "${tmpdir}/${archive_name}" -C "${tmpdir}"
  binary_path="$(find "${tmpdir}" -type f -name tigrisfs | head -n 1)"
  if [[ -z "${binary_path}" ]]; then
    nipsulidotfiles::log_error "Could not find tigrisfs binary in archive."
    rm -rf "${tmpdir}"
    return 1
  fi

  mkdir -p "${HOME}/bin"
  install -m 0755 "${binary_path}" "${HOME}/bin/tigrisfs"
  rm -rf "${tmpdir}"
  nipsulidotfiles::log_success "Installed tigrisfs into ${HOME}/bin/tigrisfs."
}

nipsulidotfiles::doctor_profile() {
  local profile="$1"
  local status=0
  local brewfile

  brewfile="$(nipsulidotfiles::brewfile_for_profile "${profile}")"
  nipsulidotfiles::log_section "Doctor ${profile}"

  if command -v brew >/dev/null 2>&1; then
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "${brewfile}"; then
      nipsulidotfiles::log_success "Brewfile ${profile} is satisfied."
    else
      status=1
    fi
  else
    nipsulidotfiles::log_error "Homebrew is not installed."
    status=1
  fi

  case "${profile}" in
    core)
      nipsulidotfiles::doctor_command gh || status=1
      nipsulidotfiles::doctor_command mas || status=1
      nipsulidotfiles::doctor_command starship || status=1
      xcode-select -p >/dev/null 2>&1 || status=1
      ;;
    cli)
      nipsulidotfiles::doctor_command rg || status=1
      nipsulidotfiles::doctor_command ag || status=1
      nipsulidotfiles::doctor_command fzf || status=1
      nipsulidotfiles::doctor_command jq || status=1
      nipsulidotfiles::doctor_command ocrmypdf || status=1
      ;;
    terminal)
      nipsulidotfiles::doctor_command ghostty || status=1
      nipsulidotfiles::doctor_command tmux || status=1
      nipsulidotfiles::doctor_command vim || status=1
      nipsulidotfiles::doctor_command nvim || status=1
      nipsulidotfiles::doctor_symlink "${HOME}/.config/ghostty/config" "${NIPSULI_DOTFILES_ROOT}/dotfiles/ghostty_config" || status=1
      nipsulidotfiles::doctor_symlink "${HOME}/.tmux.conf" "${NIPSULI_DOTFILES_ROOT}/dotfiles/.tmux.conf" || status=1
      nipsulidotfiles::doctor_symlink "${HOME}/.vimrc" "${NIPSULI_DOTFILES_ROOT}/dotfiles/.vimrc" || status=1
      ;;
    languages)
      nipsulidotfiles::doctor_command uv || status=1
      nipsulidotfiles::doctor_command fnm || status=1
      nipsulidotfiles::doctor_command bun || status=1
      nipsulidotfiles::doctor_command rustup || status=1
      nipsulidotfiles::doctor_command clojure || status=1
      nipsulidotfiles::doctor_command clj-kondo || status=1
      ;;
    apps)
      nipsulidotfiles::doctor_app "Codex.app" || status=1
      nipsulidotfiles::doctor_app "Linear.app" || status=1
      nipsulidotfiles::doctor_app "kindaVim.app" || status=1
      nipsulidotfiles::doctor_app "Zed.app" || status=1
      ;;
    mas)
      mas account >/dev/null 2>&1 || status=1
      nipsulidotfiles::doctor_app "Xcode.app" || status=1
      nipsulidotfiles::doctor_app "Slack.app" || status=1
      ;;
    virtualization)
      nipsulidotfiles::doctor_command docker || status=1
      nipsulidotfiles::doctor_command colima || status=1
      ;;
    cloud)
      nipsulidotfiles::doctor_command clerk || status=1
      nipsulidotfiles::doctor_command flyctl || status=1
      nipsulidotfiles::doctor_command tigris || status=1
      nipsulidotfiles::doctor_command tigrisfs || status=1
      nipsulidotfiles::doctor_command turso || status=1
      ;;
  esac

  return "${status}"
}

nipsulidotfiles::doctor_command() {
  if command -v "$1" >/dev/null 2>&1; then
    nipsulidotfiles::log_success "Command found: $1"
  else
    nipsulidotfiles::log_error "Missing command: $1"
    return 1
  fi
}

nipsulidotfiles::doctor_app() {
  if [[ -d "/Applications/$1" ]]; then
    nipsulidotfiles::log_success "Application found: $1"
  else
    nipsulidotfiles::log_error "Missing application: $1"
    return 1
  fi
}

nipsulidotfiles::doctor_symlink() {
  local link_path="$1"
  local expected_target="$2"
  local actual_target

  actual_target="$(readlink "${link_path}" || true)"
  if [[ "${actual_target}" == "${expected_target}" ]]; then
    nipsulidotfiles::log_success "Symlink ok: ${link_path}"
  else
    nipsulidotfiles::log_error "Symlink mismatch: ${link_path} -> ${actual_target}"
    return 1
  fi
}

nipsulidotfiles::remind_manual_installations() {
  nipsulidotfiles::log_section "Manual Steps"
  cat <<'EOF'
  - Log into GUI apps.
  - Run 'colima start' before using Docker workloads.
  - Configure Tigris credentials and mounts manually when needed.
  - Add any newly generated GPG key to GitHub.
EOF
}

main() {
  echo "This is a helper module, nothing to execute here."
  exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
