<p align="center"><img src="art/banner-2x.png"></p>

# Chris's Dotfiles

My personal macOS setup. It takes the manual labor out of provisioning a new Mac
and keeps every machine I use consistent and reproducible.

The modern stack:

| Concern | Tool | Replaces |
| --- | --- | --- |
| Shell | [**Den**](https://github.com/stacksjs/den) | zsh + oh-my-zsh |
| Prompt | Den native prompt (`.config/den.jsonc`) | starship |
| Shell plugins | Den native features | zsh-autosuggestions, zsh-syntax-highlighting, fast-syntax-highlighting, zsh-autocomplete |
| CLI tools, GUI apps, fonts, other deps | [**Pantry**](https://github.com/pantry-pm/pantry) (`deps.yaml` + `apps.yaml`/`fonts.yaml`) | Homebrew `Brewfile` + casks |
| Credentials, `.env` & app-settings sync | [**ts-backups**](https://github.com/stacksjs/ts-backups) (`.config/backups.ts` → iCloud) | mackup |

Everything Pantry can install — including Zig, Bun, Den's build toolchain — is
declared across [`deps.yaml`](./deps.yaml) _(CLI tools + Zig & more)_ and the sibling
[`apps.yaml`](./apps.yaml) / [`fonts.yaml`](./fonts.yaml) _(GUI apps + fonts)_, all
installed with a single `pantry install`.

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
| [`deps.yaml`](./deps.yaml) | CLI dependencies installed by Pantry (incl. Zig); uses the `deps:` shorthand |
| [`apps.yaml`](./apps.yaml) | GUI apps Pantry installs on macOS (Pantry registry domains + Mac App Store) |
| [`fonts.yaml`](./fonts.yaml) | Fonts Pantry installs on macOS |
| [`.config/backups.ts`](./.config/backups.ts) | What gets synced to iCloud: credentials, project `.env`s, app settings (ts-backups) |
| [`bin/dotsync`](./bin/dotsync) | Runs ts-backups (from source) against `.config/backups.ts` |
| [`bin/git-sync.ts`](./bin/git-sync.ts) | Rescues/recovers local-only git work (unpushed commits, stashes, uncommitted, untracked) |
| [`bin/dot-recover`](./bin/dot-recover) | One-shot new-machine recovery: secrets + repos + git work + mail accounts |
| [`bin/mail-profile`](./bin/mail-profile) | Generates a Mail.app config profile (`.mobileconfig`) from a `.env` of mail creds |
| [`mail-accounts.env.example`](./mail-accounts.env.example) | Template for the mail-account credentials `bin/mail-profile` reads |
| [`package.json`](./package.json) | `bun run backup` / `rescue` / `recover` / `prewipe` / `mail` scripts |
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
   - install **all** dependencies (`pantry install`) — CLI tools **and Zig** from
     `deps.yaml`, plus GUI apps and fonts from `apps.yaml` / `fonts.yaml`,
   - clone and build **Den**, then symlink it to `~/.local/bin/den`,
   - symlink `~/.denrc`, `~/.config/den.jsonc` (Den) and `~/.zshrc` (fallback),
   - **recover everything from iCloud** (`bun run recover` — see
     [Backups & restore](#backups--restore)): credentials, project `.env`s and app
     settings, then every repo cloned back to its original `~/Code` path with all
     your local-only git work (unpushed commits, stashes, uncommitted, untracked),
     then any remaining org repos, then your **mail accounts** (generates the
     config profile and opens it + Internet Accounts to finish — see
     [Mail accounts](#mail-accounts)),
   - apply macOS defaults (`.macos`).

   > Recovery needs iCloud signed in and `gh` authenticated. If either isn't ready,
   > `fresh.sh` skips it with a printed follow-up — re-run `bun run recover` once
   > iCloud has synced (and `gh auth login` if cloning needs it).

5. Restart to finalize.

> The GUI apps and fonts are installed by `pantry install` in step 4 — the lists
> live in [`apps.yaml`](./apps.yaml) and [`fonts.yaml`](./fonts.yaml), which Pantry
> reads automatically alongside `deps.yaml`. Apps and fonts come from **Pantry's
> own registry** (`registry.pantry.dev`) — each is a Pantry package keyed by
> domain (e.g. `ghostty.org`), downloaded and installed directly. **No Homebrew,
> no `brew`, nothing third-party.** **Mac App Store** apps (the `mas:` entries)
> need no extra tooling either — Pantry has built-in App Store support (the role
> [`mas`](https://github.com/mas-cli/mas) plays elsewhere): it skips any app
> already installed and opens the App Store to the rest for a one-click install.

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

- **Install a CLI tool:** add it under `deps:` in `deps.yaml`, then `pantry install`.
- **Install a GUI app or font:** add a line to `apps.yaml` (a Pantry domain like
  `- cursor.com`, or `{ mas: "<id>", name: <App> }` for a Mac App Store app) or
  `fonts.yaml` (e.g. `- inter`), then `pantry install`. Verify a package exists at
  `registry.pantry.dev/binaries/<domain>/metadata.json`.
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
untracked files, clones any remaining org repos, then sets up your **mail
accounts** (see [Mail accounts](#mail-accounts)). `fresh.sh` calls it for you;
run it by hand if iCloud wasn't synced yet at provision time.

### What's covered (secrets & settings)

- **Credentials/profile** — `~/.ssh` (keys, with perms preserved), `~/.aws`,
  `~/.config/gh`, `~/.config/github-copilot`, `~/.npmrc`, `~/.docker/config.json`,
  `~/.config/composer`.
- **Git identity** — `~/.gitconfig`, `~/.config/git`.
- **App settings** — VS Code / Cursor `settings.json`+`keybindings.json`+snippets,
  `~/.config/zed`, `~/.config/raycast` (extensions excluded).
- **Claude Code** — `~/.claude` settings, any custom commands/agents, and your
  per-project memory (`projects/<slug>/memory/**`); the ~2GB of regenerable
  session data (transcripts, file-history, caches) is excluded.
- **Project secrets** — every real `.env` / `.env.*` under `~/Code` (recursively,
  paths preserved; `.env.example` and friends skipped).
- **Mail accounts** — `~/.config/mail-accounts.env` (the creds `bin/mail-profile`
  turns into a Mail.app profile — see [Mail accounts](#mail-accounts)).

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

## Mail accounts

macOS has no supported CLI to create a Mail.app account directly, but a
**configuration profile** can define IMAP/SMTP accounts (servers, ports, SSL,
username, password) declaratively. [`bin/mail-profile`](./bin/mail-profile)
generates that profile from a `.env` of credentials and opens it for you:

```sh
cp mail-accounts.env.example ~/.config/mail-accounts.env   # then fill it in
bun run mail                                               # generates + opens the profile
```

Each account is one block in the `.env` (see
[`mail-accounts.env.example`](./mail-accounts.env.example)); it's synced to iCloud
by ts-backups (the `mail-accounts` entry in `.config/backups.ts`) and **never**
committed to this repo. On a new machine `bun run recover` (and `fresh.sh`, which
calls it) restores this file and then runs `bun run mail` for you automatically —
no extra step.

Every account is **pre-filled** as long as it has a password — custom IMAP/SMTP
take a server block; **Gmail and iCloud** just need an email + an **app password**
(`myaccount.google.com` → App passwords; `account.apple.com` → App-Specific
Passwords), with their servers preset. All pre-filled accounts go into one
configuration profile. macOS won't install a profile silently on a non-MDM Mac,
so `bun run mail` opens it and you approve it once in System Settings → General →
Device Management — every account lands from that single click, no per-account
sign-in.

An account with **no password** (or `<PREFIX>_INTERACTIVE=true`) falls back to a
one-time interactive sign-in: `bun run mail` opens System Settings → Internet
Accounts and tells you which to add. Use this only when you can't get an app
password.

> The generated `.mobileconfig` holds plaintext passwords (written to `$TMPDIR`,
> `chmod 600`) — delete it once the profile is installed.

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
