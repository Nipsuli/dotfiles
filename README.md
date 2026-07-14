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
- `languages`: uv, fnm/Node, Bun, Rust, Clojure, clj-kondo
- `apps`: Codex CLI, ChatGPT GUI, CodexBar, Zed, Sublime, Raycast, browsers, work apps
- `mas`: App Store apps including Xcode, Slack, Spark, WhatsApp, Word, Excel, To Do
- `virtualization`: Docker CLI and Colima
- `cloud`: flyctl, Tigris CLI, TigrisFS helper install, Turso, Clerk, macFUSE

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
