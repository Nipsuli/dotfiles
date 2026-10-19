#!/bin/bash
# shellcheck disable=SC2310,SC2311,SC2312,SC2249
#######################################
# Helper functions for the install script.
#######################################
set -e

readonly BREW_INSTALL_SCRIPT="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

NIPSULI_DOTFILES_ROOT="${NIPSULI_DOTFILES_ROOT:-$(pwd)}"
NIPSULI_PACKAGES="${NIPSULI_DOTFILES_ROOT}/packages/unix.tsv"

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

nipsulidotfiles::is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

nipsulidotfiles::is_arch() {
  command -v pacman >/dev/null 2>&1
}

#######################################
# Packages: packages/unix.tsv, through Homebrew on macOS and pacman on Arch.
#######################################

# Print packages/unix.tsv as a Brewfile, tapping each formula's tap.
nipsulidotfiles::unix_brewfile() {
  awk -F'\t' '
    /^#/ || NF < 2 || $1 == "-" { next }
    {
      if (split($1, part, "/") == 3 && !seen[part[1] "/" part[2]]++) {
        taps = taps "tap \"" part[1] "/" part[2] "\"\n"
      }
      brews = brews "brew \"" $1 "\"\n"
    }
    END { printf "%s%s", taps, brews }
  ' "${NIPSULI_PACKAGES}"
}

nipsulidotfiles::arch_packages() {
  awk -F'\t' '/^#/ || NF < 2 || $2 == "-" || $2 ~ /^aur:/ { next } { print $2 }' "${NIPSULI_PACKAGES}"
}

nipsulidotfiles::aur_packages() {
  awk -F'\t' '!/^#/ && $2 ~ /^aur:/ { sub(/^aur:/, "", $2); print $2 }' "${NIPSULI_PACKAGES}"
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

# Homebrew refuses formulas from taps outside its own until they are trusted.
nipsulidotfiles::trust_taps() {
  local tap

  while IFS= read -r tap; do
    brew trust --tap "${tap}"
  done < <(sed -n 's/^tap "\([^"]*\)".*/\1/p' "$1")
}

nipsulidotfiles::install_packages() {
  local brewfile
  local missing
  local status=0

  nipsulidotfiles::log_section "Installing packages"

  if nipsulidotfiles::is_macos; then
    nipsulidotfiles::ensure_xcode_commandline_tools
    nipsulidotfiles::install_homebrew
    brewfile="$(mktemp)"
    nipsulidotfiles::unix_brewfile > "${brewfile}"
    nipsulidotfiles::trust_taps "${brewfile}"
    # Upgrades are a separate step, so installing never changes versions.
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file "${brewfile}" || status=1
    rm -f "${brewfile}"
    return "${status}"
  fi

  if ! nipsulidotfiles::is_arch; then
    nipsulidotfiles::log_error "Only macOS (Homebrew) and Arch Linux (pacman) are supported."
    return 1
  fi

  missing="$(nipsulidotfiles::arch_packages | xargs pacman -T || true)"
  if [[ -n "${missing}" ]]; then
    # shellcheck disable=SC2086 # one package name per word
    sudo pacman -S --needed ${missing}
  fi
  missing="$(nipsulidotfiles::missing_aur_packages)"
  if [[ -n "${missing}" ]]; then
    if command -v yay >/dev/null 2>&1; then
      # shellcheck disable=SC2086 # one package name per word
      yay -S --needed ${missing}
    else
      nipsulidotfiles::log_error "Install these AUR packages: ${missing}"
      return 1
    fi
  fi
}

nipsulidotfiles::missing_aur_packages() {
  local package

  while IFS= read -r package; do
    pacman -Q "${package}" >/dev/null 2>&1 || printf '%s ' "${package}"
  done < <(nipsulidotfiles::aur_packages)
}

nipsulidotfiles::doctor_packages() {
  local brewfile
  local missing
  local status=0

  nipsulidotfiles::log_section "Doctor packages"

  if nipsulidotfiles::is_macos; then
    if ! command -v brew >/dev/null 2>&1; then
      nipsulidotfiles::log_error "Homebrew is not installed."
      return 1
    fi
    brewfile="$(mktemp)"
    nipsulidotfiles::unix_brewfile > "${brewfile}"
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --verbose --file "${brewfile}"; then
      nipsulidotfiles::log_success "All packages are installed."
    else
      status=1
    fi
    rm -f "${brewfile}"
    return "${status}"
  fi

  missing="$(nipsulidotfiles::arch_packages | xargs pacman -T || true)"
  missing="${missing//$'\n'/ }$(nipsulidotfiles::missing_aur_packages)"
  if [[ -n "${missing// /}" ]]; then
    nipsulidotfiles::log_error "Missing packages: ${missing}"
    return 1
  fi
  nipsulidotfiles::log_success "All packages are installed."
}

#######################################
# Config: shell, git, editors, mise, and app settings.
#######################################

nipsulidotfiles::configure() {
  # On Linux the distribution's own config stays until there is a setup that
  # works with it; on Omarchy, linking would replace its LazyVim and shell.
  if ! nipsulidotfiles::is_macos; then
    nipsulidotfiles::log_error "Config is macOS-only for now; ./install packages works here."
    return 1
  fi

  nipsulidotfiles::log_section "Configuring"
  nipsulidotfiles::setup_ssh
  nipsulidotfiles::setup_basic_env
  nipsulidotfiles::link_shell_profile
  nipsulidotfiles::configure_console_styles
  nipsulidotfiles::configure_direnv
  nipsulidotfiles::setup_git
  nipsulidotfiles::setup_keybindings
  nipsulidotfiles::configure_system_preferences
  nipsulidotfiles::configure_fzf
  nipsulidotfiles::install_helper_scripts
  nipsulidotfiles::configure_ghostty
  nipsulidotfiles::configure_vim
  nipsulidotfiles::configure_neovim
  nipsulidotfiles::configure_tmux
  nipsulidotfiles::configure_mise
  nipsulidotfiles::configure_rust
  nipsulidotfiles::configure_apps
  nipsulidotfiles::log_success "Configuration complete."
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

nipsulidotfiles::setup_ssh() {
  nipsulidotfiles::check_email_var
  nipsulidotfiles::log_info "Configuring SSH keys..."

  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"

  nipsulidotfiles::ensure_ed25519_key "${HOME}/.ssh/id_ed25519" "${EMAIL}"
  nipsulidotfiles::ensure_ed25519_key "${HOME}/.ssh/id_ed25519_exe_dev" "${EMAIL} exe.dev"
  nipsulidotfiles::configure_exe_dev_ssh
}

nipsulidotfiles::ensure_ed25519_key() {
  local key_path="$1"
  local key_comment="$2"

  if [[ -f "${key_path}" ]]; then
    if [[ ! -f "${key_path}.pub" ]]; then
      nipsulidotfiles::log_info "Creating missing public key for ${key_path}."
      ssh-keygen -y -f "${key_path}" > "${key_path}.pub"
    else
      nipsulidotfiles::log_success "SSH key already present: ${key_path}"
    fi

    chmod 600 "${key_path}"
    chmod 644 "${key_path}.pub"
    return 0
  fi

  if [[ -f "${key_path}.pub" ]]; then
    nipsulidotfiles::log_error "Public SSH key exists without private key: ${key_path}.pub"
    return 1
  fi

  nipsulidotfiles::log_info "Creating ed25519 SSH key at ${key_path}."
  ssh-keygen -t ed25519 -C "${key_comment}" -f "${key_path}" -N ""
  chmod 600 "${key_path}"
  chmod 644 "${key_path}.pub"
}

nipsulidotfiles::configure_exe_dev_ssh() {
  local ssh_config="${HOME}/.ssh/config"

  touch "${ssh_config}"
  chmod 600 "${ssh_config}"

  if nipsulidotfiles::ssh_config_has_host "${ssh_config}" "exe.dev"; then
    if grep -qF "IdentityFile ~/.ssh/id_ed25519_exe_dev" "${ssh_config}"; then
      nipsulidotfiles::log_success "exe.dev SSH config already present."
    else
      nipsulidotfiles::log_warn "exe.dev SSH config exists; ensure it uses ~/.ssh/id_ed25519_exe_dev."
    fi
    return 0
  fi

  if [[ -s "${ssh_config}" ]]; then
    printf '\n' >> "${ssh_config}"
  fi

  cat >> "${ssh_config}" <<'EOF'
Host exe.dev *.exe.xyz
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519_exe_dev
  IdentitiesOnly yes
EOF
  nipsulidotfiles::log_success "Added exe.dev SSH config."
}

nipsulidotfiles::ssh_config_has_host() {
  local ssh_config="$1"
  local host="$2"

  awk -v host="${host}" '
    /^[[:space:]]*Host[[:space:]]/ {
      for (i = 2; i <= NF; i++) {
        if ($i == host) {
          found = 1
        }
      }
    }
    END { exit found ? 0 : 1 }
  ' "${ssh_config}"
}

nipsulidotfiles::setup_git() {
  nipsulidotfiles::check_email_var
  git config --global user.email "${EMAIL}"
  git config --global pull.rebase false
  nipsulidotfiles::configure_commit_signing

  if command -v gh >/dev/null 2>&1; then
    nipsulidotfiles::setup_github_cli_auth
  fi
}

# Sign commits with the machine's SSH key; GitHub verifies it as a signing key.
nipsulidotfiles::configure_commit_signing() {
  local key_path="${HOME}/.ssh/id_ed25519"
  local signers="${HOME}/.ssh/allowed_signers"
  local public_key

  public_key="$(awk 'NR == 1 { print $1 " " $2 }' "${key_path}.pub")"
  git config --global gpg.format ssh
  git config --global user.signingkey "${key_path}"
  git config --global commit.gpgsign true
  # Lets `git log --show-signature` verify this machine's commits locally.
  git config --global gpg.ssh.allowedSignersFile "${signers}"
  nipsulidotfiles::append_to_file "${signers}" "${EMAIL} namespaces=\"git\" ${public_key}"
}

nipsulidotfiles::setup_github_cli_auth() {
  if gh auth status -h github.com >/dev/null 2>&1; then
    nipsulidotfiles::log_success "GitHub CLI already authenticated."
  else
    nipsulidotfiles::log_warn "GitHub CLI is not authenticated; starting gh auth login."
    gh auth login --hostname github.com --git-protocol ssh
  fi

  gh config set git_protocol ssh --host github.com
  nipsulidotfiles::ensure_github_ssh_key authentication
  nipsulidotfiles::ensure_github_ssh_key signing
}

# Upload ~/.ssh/id_ed25519.pub to GitHub as an authentication or signing key.
nipsulidotfiles::ensure_github_ssh_key() {
  local type="$1"
  local key_path="${HOME}/.ssh/id_ed25519.pub"
  local endpoint
  local scope
  local key_value
  local remote_keys
  local title

  case "${type}" in
    authentication) endpoint="user/keys" scope="admin:public_key" ;;
    signing) endpoint="user/ssh_signing_keys" scope="admin:ssh_signing_key" ;;
  esac

  if [[ ! -f "${key_path}" ]]; then
    nipsulidotfiles::log_error "Missing GitHub SSH public key: ${key_path}"
    return 1
  fi

  key_value="$(awk 'NR == 1 { print $1 " " $2 }' "${key_path}")"
  if [[ -z "${key_value}" ]] || [[ "${key_value}" == " " ]]; then
    nipsulidotfiles::log_error "Could not read GitHub SSH public key: ${key_path}"
    return 1
  fi

  if ! remote_keys="$(gh api "${endpoint}" --jq '.[].key' 2>/dev/null)"; then
    nipsulidotfiles::log_warn "Adding the ${scope} scope to the GitHub CLI."
    gh auth refresh -h github.com -s "${scope}"
    remote_keys="$(gh api "${endpoint}" --jq '.[].key')"
  fi

  if printf '%s\n' "${remote_keys}" | grep -qxF "${key_value}"; then
    nipsulidotfiles::log_success "GitHub already has the ${type} SSH key."
    return 0
  fi

  title="$(hostname -s) id_ed25519"
  if ! gh ssh-key add "${key_path}" --type "${type}" --title "${title}"; then
    nipsulidotfiles::log_warn "Adding the ${scope} scope to the GitHub CLI."
    gh auth refresh -h github.com -s "${scope}"
    gh ssh-key add "${key_path}" --type "${type}" --title "${title}"
  fi
  nipsulidotfiles::log_success "Uploaded GitHub ${type} key: ${title}"
}

nipsulidotfiles::setup_keybindings() {
  nipsulidotfiles::log_info "Configuring Finnish character shortcuts."
  mkdir -p "${HOME}/Library/KeyBindings"
  cat > "${HOME}/Library/KeyBindings/DefaultKeyBinding.dict" <<'EOF'
{
    "~a" = (insertText:, "ä");
    "~o" = (insertText:, "ö");
    "~A" = (insertText:, "Ä");
    "~O" = (insertText:, "Ö");
}
EOF
}

nipsulidotfiles::configure_system_preferences() {
  nipsulidotfiles::log_info "Configuring macOS defaults."

  # Keep screenshots in a predictable folder instead of scattering them on Desktop.
  mkdir -p "${HOME}/Desktop/screenshots"
  defaults write com.apple.screencapture location "${HOME}/Desktop/screenshots"

  # Make Finder useful for development: show hidden files plus path and status bars.
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true

  # Prefer a compact analog clock in the menu bar.
  defaults write com.apple.menuextra.clock IsAnalog -bool true

  # Disable smart punctuation replacements and use a fast keyboard repeat rate.
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2

  # Map Caps Lock to Escape on the internal keyboard.
  nipsulidotfiles::configure_keyboard_modifier_mapping

  # Keep the Dock small, out of the way, and attached to the right edge.
  defaults write com.apple.dock autohide -int 1
  defaults write com.apple.dock orientation right
  defaults write com.apple.dock tilesize -int 16

  # Restart affected UI services so the preference changes take effect.
  killall SystemUIServer >/dev/null 2>&1 || true
  killall Finder >/dev/null 2>&1 || true
  killall Dock >/dev/null 2>&1 || true
}

nipsulidotfiles::configure_keyboard_modifier_mapping() {
  local found=0
  local key
  local status=0

  while IFS= read -r key; do
    found=1
    # HID 0x700000039 is Caps Lock; 0x700000029 is Escape.
    defaults -currentHost write NSGlobalDomain "${key}" -array '{
      HIDKeyboardModifierMappingDst = 30064771113;
      HIDKeyboardModifierMappingSrc = 30064771129;
    }' || status=1
    nipsulidotfiles::log_success "Configured keyboard modifier mapping: ${key}"
  done < <(nipsulidotfiles::keyboard_modifier_mapping_keys)

  if [[ "${found}" -eq 0 ]]; then
    nipsulidotfiles::log_warn "Could not detect an internal keyboard for modifier mapping."
  fi

  return "${status}"
}

nipsulidotfiles::keyboard_modifier_mapping_keys() {
  local class

  # Modifier mapping keys include keyboard-specific vendor/product IDs.
  for class in AppleHIDKeyboardEventDriverV2 AppleHIDKeyboardEventDriver; do
    ioreg -r -c "${class}" -l -w0 2>/dev/null || true
  done | awk '
    /AppleHIDKeyboardEventDriver/ {
      vendor = ""
      product = ""
      built_in = 0
      keyboard = 0
    }
    /"VendorID" =/ { vendor = $NF }
    /"ProductID" =/ { product = $NF }
    /"Built-In" = Yes/ { built_in = 1 }
    /"Product" = "Apple Internal Keyboard \/ Trackpad"/ { built_in = 1 }
    /"PrimaryUsage" = 6/ { keyboard = 1 }
    /"DeviceUsagePairs" = .*"DeviceUsagePage"=1.*"DeviceUsage"=6/ { keyboard = 1 }
    vendor && product && built_in && keyboard {
      key = "com.apple.keyboard.modifiermapping." vendor "-" product "-0"
      if (!seen[key]++) {
        print key
      }
      vendor = ""
      product = ""
      built_in = 0
      keyboard = 0
    }
  '
}

nipsulidotfiles::configure_fzf() {
  local fzf_install

  command -v brew >/dev/null 2>&1 || return 0
  fzf_install="$(brew --prefix)/opt/fzf/install"
  if [[ -x "${fzf_install}" ]]; then
    "${fzf_install}" --key-bindings --completion --no-update-rc
    # shellcheck disable=SC2016
    nipsulidotfiles::append_to_shell_files '[[ -f "$HOME/.fzf.%SHELL_NAME%" ]] && source "$HOME/.fzf.%SHELL_NAME%"'
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
    if ! "${HOME}/.tmux/plugins/tpm/bin/install_plugins"; then
      nipsulidotfiles::log_error "tmux plugin installation failed."
      return 1
    fi
  else
    nipsulidotfiles::log_error "TPM plugin installer is missing."
    return 1
  fi
}

nipsulidotfiles::configure_mise() {
  # packages/unix.tsv installs mise, so it updates with the other packages.
  if ! command -v mise >/dev/null 2>&1; then
    nipsulidotfiles::log_error "mise is missing; run ./install packages first."
    return 1
  fi

  mkdir -p "${HOME}/.config/mise/conf.d"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/mise/tools.toml" "${HOME}/.config/mise/conf.d/10-dotfiles.toml"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/mise/env.sh" "${HOME}/.config/mise/env.sh"
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_file "${HOME}/.zprofile" '. "$HOME/.config/mise/env.sh"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files '. "$HOME/.config/mise/env.sh"'
  # shellcheck disable=SC2016
  nipsulidotfiles::append_to_shell_files 'eval "$(mise activate %SHELL_NAME%)"'

  # Install personal defaults even when the caller is inside another project.
  mise trust "${HOME}/.config/mise/conf.d/10-dotfiles.toml"
  (cd "${HOME}" && mise install)
  (cd "${HOME}" && mise exec node -- corepack enable yarn)
  mise reshim

  # Running apps can inherit a PATH without mise shims. Keep CLI entry points
  # in the user bin directory and let mise select the installed versions.
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${HOME}/.local/share/mise/shims/codex" "${HOME}/.local/bin/codex"
  ln -sf "${HOME}/.local/share/mise/shims/claude" "${HOME}/.local/bin/claude"
}

nipsulidotfiles::configure_rust() {
  if ! command -v rustup >/dev/null 2>&1; then
    nipsulidotfiles::log_info "Installing Rust through rustup."
    # shellcheck disable=SC2312
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  # rustup's installer adds `. "$HOME/.cargo/env"` to .zshenv, .bash_profile,
  # .bashrc, and .profile itself. Another copy in .zshrc loads it twice.
}

nipsulidotfiles::configure_apps() {
  mkdir -p "${HOME}/.config/zed"
  mkdir -p "${HOME}/.config/codebook"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/zed/settings.json" "${HOME}/.config/zed/settings.json"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/zed/keymap.json" "${HOME}/.config/zed/keymap.json"
  ln -sf "${NIPSULI_DOTFILES_ROOT}/dotfiles/codebook.toml" "${HOME}/.config/codebook/codebook.toml"
}

nipsulidotfiles::doctor_config() {
  local root="${NIPSULI_DOTFILES_ROOT}/dotfiles"
  local command
  local status=0

  nipsulidotfiles::log_section "Doctor config"

  for command in mise node npm pnpm python uv bun go rustup; do
    nipsulidotfiles::doctor_command "${command}" || status=1
  done
  nipsulidotfiles::doctor_file "${HOME}/.ssh/id_ed25519" || status=1
  nipsulidotfiles::doctor_file "${HOME}/.ssh/id_ed25519.pub" || status=1
  nipsulidotfiles::doctor_file "${HOME}/.ssh/id_ed25519_exe_dev" || status=1
  nipsulidotfiles::doctor_file "${HOME}/.ssh/id_ed25519_exe_dev.pub" || status=1
  nipsulidotfiles::doctor_exe_dev_ssh_config || status=1
  nipsulidotfiles::doctor_commit_signing || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.nipsuli_profile" "${root}/.nipsuli_profile" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.config/ghostty/config" "${root}/ghostty_config" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.tmux.conf" "${root}/.tmux.conf" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.vimrc" "${root}/.vimrc" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.config/mise/conf.d/10-dotfiles.toml" "${root}/mise/tools.toml" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.config/zed/settings.json" "${root}/zed/settings.json" || status=1
  nipsulidotfiles::doctor_symlink "${HOME}/.config/codebook/codebook.toml" "${root}/codebook.toml" || status=1
  nipsulidotfiles::doctor_tmux_plugin tpm || status=1
  nipsulidotfiles::doctor_tmux_plugin tmux-sensible || status=1
  nipsulidotfiles::doctor_tmux_plugin tmux-resurrect || status=1
  nipsulidotfiles::doctor_tmux_plugin tmux-continuum || status=1

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

nipsulidotfiles::doctor_file() {
  if [[ -f "$1" ]]; then
    nipsulidotfiles::log_success "File found: $1"
  else
    nipsulidotfiles::log_error "Missing file: $1"
    return 1
  fi
}

nipsulidotfiles::doctor_commit_signing() {
  if [[ "$(git config --global gpg.format)" == "ssh" ]] && \
    [[ "$(git config --global commit.gpgsign)" == "true" ]]; then
    nipsulidotfiles::log_success "Commits are signed with SSH."
  else
    nipsulidotfiles::log_error "Commits are not signed with SSH; run ./install config."
    return 1
  fi
}

nipsulidotfiles::doctor_tmux_plugin() {
  local plugin_path="${HOME}/.tmux/plugins/$1"

  if [[ -d "${plugin_path}/.git" ]] && git -C "${plugin_path}" remote get-url origin >/dev/null 2>&1; then
    nipsulidotfiles::log_success "tmux plugin found: $1"
  else
    nipsulidotfiles::log_error "Missing tmux plugin: $1"
    return 1
  fi
}

nipsulidotfiles::doctor_exe_dev_ssh_config() {
  local ssh_config="${HOME}/.ssh/config"

  if [[ -f "${ssh_config}" ]] && \
    nipsulidotfiles::ssh_config_has_host "${ssh_config}" "exe.dev" && \
    grep -qF "IdentityFile ~/.ssh/id_ed25519_exe_dev" "${ssh_config}"; then
    nipsulidotfiles::log_success "exe.dev SSH config found."
  else
    nipsulidotfiles::log_error "Missing exe.dev SSH config."
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

main() {
  echo "This is a helper module, nothing to execute here."
  exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
