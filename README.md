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
| CLI tools, GUI apps, fonts **+ Zig toolchain** | [**Pantry**](https://github.com/stacksjs/pantry) (`deps.yaml`) | Homebrew `Brewfile` + casks |
| Credentials, `.env` & app-settings sync | [**ts-backups**](https://github.com/stacksjs/ts-backups) (`.config/backups.ts` → iCloud) | mackup |
| GUI apps reference | [`apps.md`](./apps.md) (catalogue of the apps Pantry installs) | — |

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
| [`apps.md`](./apps.md) | Catalogue of the GUI apps + fonts Pantry installs (entry → source) |
| [`.config/backups.ts`](./.config/backups.ts) | What gets synced to iCloud: credentials, project `.env`s, app settings (ts-backups) |
| [`bin/dotsync`](./bin/dotsync) | Runs ts-backups (from source) against `.config/backups.ts` |
| [`bin/git-sync.ts`](./bin/git-sync.ts) | Rescues/recovers local-only git work (unpushed commits, stashes, uncommitted, untracked) |
| [`bin/dot-recover`](./bin/dot-recover) | One-shot new-machine recovery: secrets + repos + git work |
| [`package.json`](./package.json) | `bun run backup` / `rescue` / `recover` / `prewipe` scripts |
| [`fresh.sh`](./fresh.sh) | One-shot provisioning script for a new Mac |
| [`clone.sh`](./clone.sh) | Clones every repo in the stacksjs / home-lang / cwcss / zig-utils orgs |
| [`ssh.sh`](./ssh.sh) | Generates a new SSH key for GitHub |
| [`.macos`](./.macos) | macOS `defaults` tweaks |
| [`zed.json`](./zed.json) | Zed editor settings |

## Fresh macOS setup

### 1. Back up the old machine first

- Run a full off-machine sync to iCloud: `cd ~/.dotfiles && bun run prewipe`.
  This snapshots credentials, project `.env`s and app settings **and** rescues all
  your local-only git work — unpushed commits, stashes, uncommitted changes,
  untracked files and any no-remote repos (replaces the old `mackup backup`, and
  means you no longer have to manually push every branch/stash first).
- **Wait for iCloud to finish uploading** (see the warning under
  [Backups & restore](#backups--restore)) before erasing.
- Save anything still not covered (large local databases, other app data, etc.).

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
   - install **all** dependencies from `deps.yaml` (`pantry install`) — CLI tools,
     GUI apps, fonts **and Zig** (Den's toolchain),
   - clone and build **Den**, then symlink it to `~/.local/bin/den`,
   - symlink `~/.denrc`, `~/.config/den.jsonc` (Den) and `~/.zshrc` (fallback),
   - **recover everything from iCloud** (`bun run recover` — see
     [Backups & restore](#backups--restore)): credentials, project `.env`s and app
     settings, then every repo cloned back to its original `~/Code` path with all
     your local-only git work (unpushed commits, stashes, uncommitted, untracked),
     then any remaining org repos,
   - apply macOS defaults (`.macos`).

   > Recovery needs iCloud signed in and `gh` authenticated. If either isn't ready,
   > `fresh.sh` skips it with a printed follow-up — re-run `bun run recover` once
   > iCloud has synced (and `gh auth login` if cloning needs it).

5. Restart to finalize.

> The GUI apps and fonts are installed by `pantry install` in step 4 — see
> [`apps.md`](./apps.md) for the catalogue. Pantry installs the CLI tools natively
> but shells out to **Homebrew** for the `apps:`/`fonts:` casks and to `mas` for
> Mac App Store apps, so those need [Homebrew](https://brew.sh) present and the
> App Store signed in (`mas account`); casks may prompt for your password. The
> core setup (shell, tools, Den, recovery) works without Homebrew — only the GUI
> apps are skipped if it's absent.

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

- **Install a CLI tool or GUI app:** add it to `deps.yaml` — a `dependencies:`
  entry for a CLI tool, or an `apps:` entry for an app (`- cursor` for a
  Homebrew cask of that name, or `{ mas: "<id>", name: <App> }` for a Mac App
  Store app) — then `pantry install`.
- **Sync a new secret/setting:** add it (or a new app's config) to
  `.config/backups.ts`, then `bun run backup`.
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

## Backups & restore

Everything that a macOS wipe would otherwise destroy is synced to **iCloud Drive**
(`~/Library/Mobile Documents/com~apple~CloudDocs/ts-backups`) — so it survives the
wipe, syncs across machines, and **never touches this public git repo**. There are
two halves:

1. **Secrets & settings** — credentials, project `.env`s and app settings, via
   [ts-backups](https://github.com/stacksjs/ts-backups) (the mackup successor),
   declared in [`.config/backups.ts`](./.config/backups.ts).
2. **Local-only git work** — unpushed commits, every stash, uncommitted changes,
   untracked files, and repos with no remote, via [`bin/git-sync.ts`](./bin/git-sync.ts).
   These exist **nowhere else** and re-cloning from GitHub will not bring them back.

### Before a wipe

```sh
cd ~/.dotfiles
bun run prewipe    # = backup (secrets/.env/settings) + rescue (all local git work)
```

Or run the halves separately: `bun run backup` and `bun run rescue`.
`bun run list` shows what's in iCloud.

> ⚠️ **Wait for iCloud to finish uploading before you wipe.** These files are
> written locally first; iCloud uploads them in the background and there's no
> reliable CLI to confirm completion. Check Finder (the `ts-backups` folder shows
> no pending-upload arrows) or System Settings → your name → iCloud before erasing.

### After a reinstall — one command

```sh
cd ~/.dotfiles && bun run recover
```

`recover` ([`bin/dot-recover`](./bin/dot-recover)) does the whole thing: restores
credentials/`.env`s/settings, clones **every repo back to its original `~/Code`
path** and replays your unpushed commits, stashes, uncommitted changes and
untracked files, then clones any remaining org repos. `fresh.sh` calls it for you;
run it by hand if iCloud wasn't synced yet at provision time.

### What's covered (secrets & settings)

- **Credentials/profile** — `~/.ssh` (keys, with perms preserved), `~/.aws`,
  `~/.config/gh`, `~/.config/github-copilot`, `~/.npmrc`, `~/.docker/config.json`,
  `~/.config/composer`.
- **Git identity** — `~/.gitconfig`, `~/.config/git`.
- **App settings** — VS Code / Cursor `settings.json`+`keybindings.json`+snippets,
  `~/.config/zed`, `~/.config/raycast` (extensions excluded).
- **Project secrets** — every real `.env` / `.env.*` under `~/Code` (recursively,
  paths preserved; `.env.example` and friends skipped).

Each entry is its own timestamped, retained snapshot, so you can restore one thing
in isolation:

```sh
./bin/dotsync restore --only ssh --overwrite          # just the SSH keys
./bin/dotsync restore --only project-envs --overwrite # just the project .env files
```

### How the git rescue works

`bin/git-sync.ts rescue` walks `~/Code` and, for each repo, bundles only the
objects that aren't already on a remote (`git bundle --all --not --remotes`) plus
every stash and your uncommitted/untracked files; a repo with no remote is bundled
in full. It records a manifest of all repos and their remotes so `recover` can
rebuild your exact layout. **Nothing is pushed and your working repos are left
untouched.** Restore is non-destructive: bundled refs land under `refs/rescued/*`,
branches only fast-forward, and a diverged branch is flagged for you to merge by
hand.

> ts-backups runs from source via `bun` (it isn't published to npm). `bin/dotsync`
> finds your local checkout — `~/Code/Libraries/ts-backups`, `~/Code/ts-backups`,
> or `~/Code/stacksjs/ts-backups` — and clones it if missing.

> **Note:** secrets live in your iCloud, which you're trusting with them. Your
> `gh` token lives in the macOS keyring (not a file), so it doesn't transfer —
> on a new machine the SSH keys cover git, and `gh auth login` re-auths the CLI.

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
