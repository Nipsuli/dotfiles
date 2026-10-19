# dotfiles

My personal dotfiles and the command-line tools every machine of mine needs.
Feel free to take a look and copy stuff you find suitable. I'm also open for
suggestions for improving this setup!

How to install:

- git clone this repo
- `EMAIL=<your email address here> ./install`

The installer works on macOS, through Homebrew, and on Arch Linux, through
pacman and the AUR. It has two parts:

- `./install packages` installs the tools in `packages/unix.tsv`: shell
  helpers, editors, linters, Clojure, and a native build toolchain.
- `./install config` links the config files and sets up the shell, SSH keys,
  git commit signing, mise, Rust, Neovim, tmux, Ghostty, and Zed, plus the
  macOS defaults and keybindings. It runs on macOS only for now: on Linux the
  distribution's own config stays (on Omarchy, its LazyVim and shell setup)
  until there is a setup that works with it.

`./install` runs both, or only the packages on Linux; `./install doctor`
checks them. Installing never upgrades a package; run `brew upgrade` or
`pacman -Syu` for that.

GUI apps, App Store apps, and per-machine packages are not here. My private
fleet repository installs, audits, and updates those on each of my machines,
together with the list above.

Stuff:

- Scripts linted with [ShellCheck](https://github.com/koalaman/shellcheck)
- Trying to follow Google's
  [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## Packages

`packages/unix.tsv` has one line per tool: its Homebrew formula and its Arch
package, tab-separated. `aur:` marks an AUR package and `-` a tool that kind of
machine gets elsewhere. Formulas from a tap are written as `owner/tap/name`;
the installer taps and trusts the tap, because Homebrew refuses formulas from
untrusted taps.

## Commit signing

Commits are signed with the machine's SSH key, `~/.ssh/id_ed25519`.
`./install config` sets git up, writes `~/.ssh/allowed_signers` so
`git log --show-signature` can verify locally, and uploads the key to GitHub as
a signing key. The upload needs the `admin:ssh_signing_key` scope; the
installer asks `gh` for it when missing.

## Tool versions

Mise owns Node and its bundled npm/npx, Bun, Python, uv, pnpm, Go, Java (for
Clojure), and personal npm CLIs. `dotfiles/mise/tools.toml` records the
defaults and is linked into `~/.config/mise/conf.d/10-dotfiles.toml`. Project
`mise.toml` files override these defaults. Rust still uses rustup.

The installer adds shell activation and mise shims for login shells. For a
migration, first remove fnm/asdf/pyenv activation and standalone Bun/pnpm PATH
blocks from your shell startup files. Restart terminal and coding apps after
migrating so their child processes inherit the new environment.

Edit `dotfiles/mise/tools.toml` to change shared defaults, then run
`(cd ~ && mise install)`. `mise use --global` writes machine-specific overrides
in `~/.config/mise/config.toml`. Manage additional personal npm CLIs with
`mise use --global npm:<package>@<version>` instead of `npm install -g`.
Use `mise which node` and `mise ls --current` to inspect the selected tools.

Before removing an old manager, migrate its global commands and check that no
running process or virtual environment depends on its files. Keep npm's download
cache unless it is faulty or you need the disk space.
