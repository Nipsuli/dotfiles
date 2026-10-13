# Restore an inherited mise session before cleaning its original PATH.
if [ -n "${__MISE_DIFF:-}" ] && command -v mise >/dev/null 2>&1; then
  if [ -n "${BASH_VERSION:-}" ]; then
    mise_deactivation="$(MISE_SHELL=bash command mise deactivate)"
    eval "${mise_deactivation}"
  elif [ -n "${ZSH_VERSION:-}" ]; then
    mise_deactivation="$(MISE_SHELL=zsh command mise deactivate)"
    eval "${mise_deactivation}"
  fi
fi
unset __MISE_ORIG_PATH mise_deactivation

# Sourced by login shells. Shims also work without mise's interactive hook.
# Drop paths inherited from retired managers when an app opens a new shell.
mise_clean_path=""
mise_remaining_path="${PATH}"
while [ -n "${mise_remaining_path}" ]; do
  mise_path_entry="${mise_remaining_path%%:*}"
  if [ "${mise_remaining_path}" = "${mise_path_entry}" ]; then
    mise_remaining_path=""
  else
    mise_remaining_path="${mise_remaining_path#*:}"
  fi
  case "${mise_path_entry}" in
    "${HOME}/.local/share/fnm"/*|"${HOME}/.local/state/fnm_multishells"/*|\
    "${HOME}/.asdf/shims"|"${HOME}/.pyenv/bin"|"${HOME}/.pyenv/shims"|\
    "${HOME}/.bun/bin"|"${HOME}/Library/pnpm"|\
    "${HOME}/.local/bin"|"${HOME}/.local/share/mise/shims") continue ;;
    *) ;;
  esac
  mise_clean_path="${mise_clean_path:+${mise_clean_path}:}${mise_path_entry}"
done
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${mise_clean_path}"
unset mise_clean_path mise_remaining_path mise_path_entry
unset FNM_DIR FNM_MULTISHELL_PATH FNM_ARCH FNM_LOGLEVEL FNM_NODE_DIST_MIRROR
unset FNM_COREPACK_ENABLED FNM_RESOLVE_ENGINES FNM_VERSION_FILE_STRATEGY
unset BUN_INSTALL PNPM_HOME PYENV_ROOT
