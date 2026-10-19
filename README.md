# dotfiles

My config files and the command-line tools I want on every machine. Feel free
to copy anything useful; suggestions are welcome.

## Install

```sh
git clone https://github.com/Nipsuli/dotfiles.git
cd dotfiles
EMAIL=<your email> ./install
```

| Command | What it does |
| --- | --- |
| `./install` | Both steps below |
| `./install packages` | Installs the tools in `packages/unix.tsv` with Homebrew (macOS) or pacman and the AUR (Arch Linux) |
| `./install config` | Links the config files and sets up the shell, git, SSH keys, and mise. macOS only for now |
| `./install doctor` | Checks both |

Installing never upgrades anything; use your package manager for that. GUI
apps and per-machine packages are managed outside this repository.

## Layout

| Path | Contents |
| --- | --- |
| `packages/unix.tsv` | One tool per line: Homebrew name, Arch name. `aur:` marks an AUR package, `-` means none |
| `dotfiles/` | Config files, linked into place by `./install config` |
| `dotfiles/mise/tools.toml` | Default language runtimes and CLIs, linked as `~/.config/mise/conf.d/10-dotfiles.toml` |
| `scripts/` | Small helper scripts, linked into `~/bin` |

Formulas from a Homebrew tap are written as `owner/tap/name`; the installer
trusts the tap first.

## Notes

- Language runtimes come from mise. Change a default in
  `dotfiles/mise/tools.toml`, then run `(cd ~ && mise install)`. A project's own
  `mise.toml` overrides it.
- Commits are signed with the machine's SSH key, which the installer uploads to
  GitHub as a signing key.
- Scripts are checked with [ShellCheck](https://github.com/koalaman/shellcheck)
  and follow Google's
  [Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
