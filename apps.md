# GUI Applications & Fonts

These are declared as dependencies in [`deps.yaml`](./deps.yaml) (the `apps:`,
`mas:` and `fonts:` entries) and installed by **Pantry** alongside the CLI tools
— `pantry install` provisions `.app` bundles too, via its desktop-app support
(Homebrew cask for `cask:` apps, the Mac App Store for `mas:` apps).

This file is the human-readable catalogue: what each app is, and its exact
cask name / App Store id, so the list stays self-documenting and easy to edit.

> If you prefer to install one manually: `brew install --cask <cask>` for a
> desktop app, or `mas install <id>` for an App Store app.

## Desktop apps (`cask:`)

| App | Cask | Notes |
| --- | --- | --- |
| 1Password | `1password` | Password manager |
| Arc | `arc` | Browser |
| Cursor | `cursor` | Editor |
| Visual Studio Code | `visual-studio-code` | Editor |
| Discord | `discord` | Chat |
| Docker | `docker` | Containers |
| GitHub Desktop | `github` | Git GUI |
| Ghostty | `ghostty` | Terminal — point its shell setting at `~/.local/bin/den` |
| IINA | `iina` | Media player |
| ImageOptim | `imageoptim` | Image compression |
| Insomnia | `insomnia` | API client |
| Logi Options+ | `logi-options-plus` | Mouse/keyboard |
| MediaInfo | `mediainfo` | Media metadata |
| Muzzle | `muzzle` | Mute notifications while screen-sharing |
| Hidden Bar | `hiddenbar` | Menu bar manager |
| Raycast | `raycast` | Launcher |
| Rewind | `rewind` | Recall |
| Slack | `slack` | Chat |
| The Unarchiver | `the-unarchiver` | Archives |
| Transmit | `transmit` | FTP/S3 client |
| VLC | `vlc` | Media player |
| Pearcleaner | `pearcleaner` | App uninstaller |

## Mac App Store (`mas:`)

| App | App Store id |
| --- | --- |
| AdBlock | `1402042596` |
| Grammarly for Safari | `1462114288` |
| Honey | `1472777122` |
| Wappalyzer | `1520333300` |
| WhatsApp | `1147396723` |

## Fonts (`fonts:`)

| Font | Cask |
| --- | --- |
| Inter | `font-inter` |
| Lato | `font-lato` |
| Meslo LG Nerd Font | `font-meslo-lg-nerd-font` (terminal / Den prompt glyphs) |
| Open Sans | `font-open-sans` |
| Roboto | `font-roboto` |
| Source Code Pro | `font-source-code-pro` |
| Source Code Pro (Powerline) | `font-source-code-pro-for-powerline` |
