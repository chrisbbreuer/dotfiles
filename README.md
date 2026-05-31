<p align="center"><img src="art/banner-2x.png"></p>

# Chris's Dotfiles

My personal macOS setup. It takes the manual labor out of provisioning a new Mac
and keeps every machine I use consistent and reproducible.

This setup is **Homebrew-free, oh-my-zsh-free, starship-free and mackup-free**.
The modern stack:

| Concern | Tool | Replaces |
| --- | --- | --- |
| Shell | [**Den**](https://github.com/stacksjs/den) | zsh + oh-my-zsh |
| Prompt | Den native prompt (`.config/den.jsonc`) | starship |
| Shell plugins | Den native features | zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting, zsh-autocomplete |
| CLI packages | [**Pantry**](https://github.com/stacksjs/pantry) (`deps.yaml`) | Homebrew `Brewfile` |
| Toolchain | Zig 0.17-dev via Pantry (`bin/install-zig-dev`) | — |
| App-settings backup | [**ts-backups**](https://github.com/stacksjs/ts-backups) (`backups.config.ts`) | mackup |
| GUI apps & fonts | manual / `mas` (`apps.md`) | Homebrew casks |

## How Den is configured

Den splits configuration into two files, both symlinked from this repo:

- **[`.denrc`](./.denrc)** → `~/.denrc` — a startup *script*, sourced line-by-line
  like `.zshrc`. Holds environment variables, `$PATH`, and `source`s the shared
  [`aliases.zsh`](./aliases.zsh).
- **[`.config/den.jsonc`](./.config/den.jsonc)** → `~/.config/den.jsonc` — the
  *declarative* config (JSONC). Holds the prompt format, syntax highlighting,
  inline autosuggestions, completion and history search. This is what replaces
  `starship.toml` and the cloned zsh plugins.

## Repository layout

| Path | Purpose |
| --- | --- |
| [`.denrc`](./.denrc) | Den startup script: env, `$PATH`, aliases (primary shell) |
| [`.config/den.jsonc`](./.config/den.jsonc) | Den declarative config: prompt, highlighting, completion |
| [`.zshrc`](./.zshrc) | Trimmed **fallback** zsh config with an opt-in `exec den` |
| [`aliases.zsh`](./aliases.zsh) | Aliases shared by both shells (POSIX-compatible) |
| [`deps.yaml`](./deps.yaml) | CLI dependencies installed by Pantry |
| [`apps.md`](./apps.md) | GUI apps, fonts and Mac App Store apps to install manually |
| [`backups.config.ts`](./backups.config.ts) | App-settings backup config (ts-backups) |
| [`bin/install-zig-dev`](./bin/install-zig-dev) | Installs/activates Zig 0.17-dev into Pantry's store |
| [`fresh.sh`](./fresh.sh) | One-shot provisioning script for a new Mac |
| [`clone.sh`](./clone.sh) | Clones my working repositories |
| [`ssh.sh`](./ssh.sh) | Generates a new SSH key for GitHub |
| [`.macos`](./.macos) | macOS `defaults` tweaks |
| [`zed.json`](./zed.json) | Zed editor settings |

## Fresh macOS setup

### 1. Back up the old machine first

- Push all git branches and stashes.
- Save anything not synced to iCloud (local databases, app data, etc.).
- Run a fresh app-settings backup: `cd ~/.dotfiles && bunx ts-backups backup`
  (replaces the old `mackup backup`).

### 2. Provision the new machine

1. Update macOS to the latest version (System Settings → Software Update).
2. Generate a new SSH key for GitHub:

   ```sh
   curl https://raw.githubusercontent.com/chrisbbreuer/dotfiles/HEAD/ssh.sh | sh -s "<your-email-address>"
   ```

   Add the printed public key at <https://github.com/settings/keys>.
3. Clone this repo to `~/.dotfiles`:

   ```sh
   git clone git@github.com:chrisbbreuer/dotfiles.git ~/.dotfiles
   ```

4. Run the installer:

   ```sh
   cd ~/.dotfiles && ./fresh.sh
   ```

   `fresh.sh` is idempotent and will:
   - install **Pantry** (the package manager),
   - install all CLI tools from `deps.yaml` (`pantry install`),
   - install **Zig 0.17-dev** (`bin/install-zig-dev`),
   - clone and build **Den**, then symlink it to `~/.local/bin/den`,
   - symlink `~/.denrc`, `~/.config/den.jsonc` (Den) and `~/.zshrc` (fallback),
   - restore app settings with **ts-backups**,
   - clone my repositories (`clone.sh`),
   - apply macOS defaults (`.macos`).

5. Install the GUI apps and fonts listed in [`apps.md`](./apps.md).
6. Restart to finalize.

### 3. Start using Den

Open a new terminal and run `den`. To have your terminal launch Den directly,
point its shell/command setting at `~/.local/bin/den`, or uncomment the opt-in
`exec den` line at the bottom of [`.zshrc`](./.zshrc).

To make Den your login shell:

```sh
echo "$HOME/.local/bin/den" | sudo tee -a /etc/shells
chsh -s "$HOME/.local/bin/den"
```

## Day-to-day

- **Install a CLI tool:** add it to `deps.yaml`, then `pantry install`.
- **Add an alias:** edit `aliases.zsh` (loaded by both shells), then `reloadshell`.
- **Change env / `$PATH`:** edit `.denrc`, then `reloadshell` (`exec $SHELL`).
- **Change prompt / highlighting / completion:** edit `.config/den.jsonc`
  (hot-reloads automatically).
- **Update Zig:** `./bin/install-zig-dev` (pulls the latest 0.17-dev nightly).
- **Rebuild Den after pulling:** `cd ~/Code/den && zig build -Doptimize=ReleaseFast`.

### The prompt

Configured in `.config/den.jsonc` via `prompt.format` — no starship. Placeholders
include `{path}`, `{git}`, `{symbol}`, `{modules}`, `{exitcode}` and per-language
modules like `{bun}`, `{node}`, `{zig}`, `{python}`. Tweak to taste.

### Native plugins

Den's autosuggestions, syntax highlighting, completion and fuzzy history search
are **built in** — toggled via `line_editor`, `completion` and `history` in
`.config/den.jsonc`. There are no cloned zsh plugin repos to maintain. To develop
your own Den plugin, see Den's `docs/PLUGIN_DEVELOPMENT.md`.

## App-settings backup

App preferences are backed up/restored with
[ts-backups](https://github.com/stacksjs/ts-backups) (an iCloud-synced,
TypeScript-configured successor to mackup). Config lives in `backups.config.ts`.

```sh
cd ~/.dotfiles
bunx ts-backups backup    # snapshot app settings to iCloud
bunx ts-backups restore   # restore on a new machine
```

## Cleaning your old Mac (optional)

After the new Mac is set up you can
[erase and reinstall macOS](https://support.apple.com/guide/mac-help/erase-and-reinstall-macos-mh27903/mac)
on the old one. Make sure you backed everything up first.

## Thanks

Originally based on [Dries Vintens's dotfiles](https://github.com/driesvints/dotfiles),
with inspiration from [Zach Holman](https://github.com/holman/dotfiles),
[Mathias Bynens](https://github.com/mathiasbynens/dotfiles) and the
[GitHub does dotfiles](https://dotfiles.github.io/) project. Banner by
[Caneco](https://twitter.com/caneco). Thanks to everyone who open-sources their
dotfiles.
