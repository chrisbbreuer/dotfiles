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
| CLI packages **+ Zig toolchain** | [**Pantry**](https://github.com/stacksjs/pantry) (`deps.yaml`) | Homebrew `Brewfile` |
| App-settings backup | [**ts-backups**](https://github.com/stacksjs/ts-backups) (`backups.config.ts`) | mackup |
| GUI apps & fonts | manual / `mas` (`apps.md`) | Homebrew casks |

Everything Pantry can install — including **Zig**, Den's build toolchain — is
declared in [`deps.yaml`](./deps.yaml) and installed with a single `pantry install`.

## How Den is configured

Den splits configuration into two files, both symlinked from this repo:

- **[`.denrc`](./.denrc)** → `~/.denrc` — a startup *script*, sourced line-by-line
  like `.zshrc`. It just `source`s the two shell-neutral files that both Den and
  the zsh fallback share: [`env.sh`](./env.sh) (environment + `$PATH`) and
  [`aliases.sh`](./aliases.sh) (aliases).
- **[`.config/den.jsonc`](./.config/den.jsonc)** → `~/.config/den.jsonc` — the
  *declarative* config (JSONC). Holds the prompt format, syntax highlighting,
  inline autosuggestions, completion and history search. This is what replaces
  `starship.toml` and the cloned zsh plugins.

Both shells source the same `env.sh` / `aliases.sh`, so there is a single source
of truth — no duplicated `$PATH` or alias lists between Den and zsh.

## Repository layout

| Path | Purpose |
| --- | --- |
| [`.denrc`](./.denrc) | Den startup script: env, `$PATH`, aliases (primary shell) |
| [`.config/den.jsonc`](./.config/den.jsonc) | Den declarative config: prompt, highlighting, completion |
| [`.zshrc`](./.zshrc) | Trimmed **fallback** zsh config with an opt-in `exec den` |
| [`env.sh`](./env.sh) | Environment + `$PATH`, shared by both shells (POSIX-sh) |
| [`aliases.sh`](./aliases.sh) | Aliases, shared by both shells (POSIX-sh) |
| [`deps.yaml`](./deps.yaml) | All CLI dependencies (incl. Zig) installed by Pantry |
| [`apps.md`](./apps.md) | GUI apps, fonts and Mac App Store apps to install manually |
| [`backups.config.ts`](./backups.config.ts) | App-settings backup config (ts-backups) |
| [`fresh.sh`](./fresh.sh) | One-shot provisioning script for a new Mac |
| [`clone.sh`](./clone.sh) | Clones my working repositories |
| [`ssh.sh`](./ssh.sh) | Generates a new SSH key for GitHub |
| [`.macos`](./.macos) | macOS `defaults` tweaks |
| [`zed.json`](./zed.json) | Zed editor settings |

## Fresh macOS setup

### 1. Back up the old machine first

- Push all git branches and stashes.
- Save anything not synced to iCloud (local databases, app data, etc.).
- Run a fresh app-settings backup: `cd ~/.dotfiles && bunx ts-backups start`
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
   - install **all** dependencies from `deps.yaml` (`pantry install`) — CLI tools
     **and Zig**, Den's toolchain,
   - clone and build **Den**, then symlink it to `~/.local/bin/den`,
   - symlink `~/.denrc`, `~/.config/den.jsonc` (Den) and `~/.zshrc` (fallback),
   - clone my repositories (`clone.sh`),
   - apply macOS defaults (`.macos`).

5. Install the GUI apps and fonts listed in [`apps.md`](./apps.md).
6. Copy your latest **ts-backups** snapshot of app settings from iCloud back into
   place (see [App-settings backup](#app-settings-backup)).
7. Restart to finalize.

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
- **Add an alias:** edit `aliases.sh` (loaded by both shells), then `reloadshell`.
- **Change env / `$PATH`:** edit `env.sh` (loaded by both shells), then `reloadshell` (`exec $SHELL`).
- **Change prompt / highlighting / completion:** edit `.config/den.jsonc`
  (hot-reloads automatically).
- **Update / change Zig:** edit the `ziglang.org` pin in `deps.yaml`, then
  `pantry install`.
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

App preferences are snapshotted with [ts-backups](https://github.com/stacksjs/ts-backups),
the successor to mackup. Config lives in `backups.config.ts`, which writes snapshots
to iCloud Drive so they sync across machines.

```sh
cd ~/.dotfiles
bunx ts-backups start    # snapshot app settings to iCloud
```

> ts-backups currently implements **backup only**. To "restore" on a new machine,
> copy the latest snapshot from
> `~/Library/Mobile Documents/com~apple~CloudDocs/ts-backups` back into place
> manually. (A first-class `restore` command is a planned ts-backups feature.)

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
