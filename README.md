# dotfiles

My personal dotfiles + computer (Mac) setup scripts. Feel free to take a look
and copy stuff you find suitable. I'm also open for suggestions for improving
this setup!

How to install the default setup:

- git clone this repo
- `EMAIL=<your email address here> ./install_mac`

The installer is split into profiles backed by curated Brewfiles. Packages live
in `brewfiles/Brewfile.*`; shell links, editor setup, language installers, and
other post-install configuration live in `nipsulidotfiles.sh`.

Profiles:

- `core`: Homebrew, App Store CLI, GitHub CLI, GPG, shell basics, fonts, starship
- `cli`: terminal utilities such as ripgrep, fzf, jq, git-lfs, cloc, ocrmypdf
- `terminal`: Ghostty, tmux, Vim, Neovim, CosmicNvim
- `languages`: mise, Node, Bun, Python, uv, pnpm, personal CLIs, Rust, Clojure, clj-kondo
- `apps`: ChatGPT GUI, CodexBar, Zed, Sublime, Raycast, browsers, work apps
- `mas`: App Store apps including Xcode, Slack, Spark, WhatsApp, Word, Excel, To Do
- `virtualization`: Docker CLI and Colima
- `cloud`: flyctl, Tigris CLI, TigrisFS helper install, Turso, macFUSE

Useful commands:

```sh
./install_mac list
./install_mac dry-run apps cloud
./install_mac doctor terminal languages
EMAIL=<your email address here> ./install_mac install core cli terminal
```

`./install_mac` with no subcommand installs all profiles. Tigris credentials and
bucket mounts are intentionally manual; the script only installs and checks the
tools.

Stuff:

- Scripts linted with [ShellCheck](https://github.com/koalaman/shellcheck)
- Trying to follow Google's
  [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Tested manually in virtual box with the help of
  [this](https://github.com/myspaghetti/macos-virtualbox) setup script.

## Tool versions

Mise owns Node and its bundled npm/npx, Bun, Python, uv, pnpm, and personal
npm CLIs. `dotfiles/mise/tools.toml` records the defaults and is linked into
`~/.config/mise/conf.d/10-dotfiles.toml`. Project `mise.toml` files override
these defaults. Rust still uses rustup; Homebrew installs system utilities and
apps. Tigris uses the Homebrew `cloud` profile instead of the old npm package
whose `t3` alias conflicts with T3 Code.

Run `./install_mac install languages` to install mise from Homebrew and these
defaults.
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
