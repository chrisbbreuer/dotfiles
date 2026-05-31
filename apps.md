# GUI Applications & Fonts

These are declared in [`deps.yaml`](./deps.yaml) (the `apps:` and `fonts:`
sections) and installed by **Pantry** alongside the CLI tools — `pantry install`
provisions `.app` bundles and fonts too, on macOS.

Each `apps:` entry is one of:

| Form in `deps.yaml` | Meaning |
| --- | --- |
| `- cursor` | Homebrew cask of that name (`brew install --cask cursor`) |
| `- { cask: <token> }` | explicit Homebrew cask |
| `- { mas: "<id>", name: <App> }` | Mac App Store app (`mas install <id>`) |

`fonts:` entries are Homebrew font casks; the `font-` prefix is added
automatically if you omit it.

Pantry reads these sections and shells out to `brew install --cask` / `mas
install`. Installs are idempotent — re-running `pantry install` only installs
what's missing. Mac App Store apps need the `mas` CLI installed and signed in
(`mas account`); cask apps need Homebrew.

This file is the human-readable catalogue: what each app is and how Pantry
installs it.

## Apps (`apps:`)

| App | `deps.yaml` entry | Source |
| --- | --- | --- |
| 1Password | `1password` | Homebrew cask |
| Arc | `arc` | Homebrew cask |
| Cursor | `cursor` | Homebrew cask |
| Discord | `discord` | Homebrew cask |
| Docker Desktop | `docker` | Homebrew cask |
| Ghostty | `ghostty` | Homebrew cask — point its shell setting at `~/.local/bin/den` |
| GitHub Desktop | `github` | Homebrew cask |
| Hidden Bar | `hiddenbar` | Homebrew cask |
| IINA | `iina` | Homebrew cask |
| ImageOptim | `imageoptim` | Homebrew cask |
| Insomnia | `insomnia` | Homebrew cask |
| Logi Options+ | `logi-options-plus` | Homebrew cask |
| MediaInfo | `mediainfo` | Homebrew cask |
| Muzzle | `muzzle` | Homebrew cask |
| Pearcleaner | `pearcleaner` | Homebrew cask |
| Raycast | `raycast` | Homebrew cask |
| Rewind | `rewind` | Homebrew cask |
| Slack | `slack` | Homebrew cask |
| The Unarchiver | `the-unarchiver` | Homebrew cask |
| Transmit | `transmit` | Homebrew cask |
| Visual Studio Code | `visual-studio-code` | Homebrew cask |
| VLC | `vlc` | Homebrew cask |
| AdBlock | `{ mas: "1402042596", name: AdBlock }` | Mac App Store |
| Grammarly for Safari | `{ mas: "1462114288", name: Grammarly for Safari }` | Mac App Store |
| Honey | `{ mas: "1472777122", name: Honey }` | Mac App Store |
| Wappalyzer | `{ mas: "1520333300", name: Wappalyzer }` | Mac App Store |
| WhatsApp | `{ mas: "1147396723", name: WhatsApp }` | Mac App Store |

## Fonts (`fonts:`)

Listed in `deps.yaml` by cask name; all install via Homebrew cask.

| Font | Cask |
| --- | --- |
| Inter | `font-inter` |
| Lato | `font-lato` |
| Meslo LG Nerd Font | `font-meslo-lg-nerd-font` (terminal / Den prompt glyphs) |
| Open Sans | `font-open-sans` |
| Roboto | `font-roboto` |
| Source Code Pro | `font-source-code-pro` |
| Source Code Pro (Powerline) | `font-source-code-pro-for-powerline` |
