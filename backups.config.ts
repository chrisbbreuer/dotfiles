import type { BackupConfig } from 'ts-backups'

// Application-settings backup config — replaces the old `.mackup.cfg`.
// Run with: bunx ts-backups backup   /   bunx ts-backups restore
const config: BackupConfig = {
  verbose: true,
  storage: {
    // 'local' | 'icloud' | 'dropbox' | 'google-drive'
    engine: 'icloud',
    path: 'ts-backups',
    symlink: true,
  },
  // Empty = let ts-backups autodetect supported apps.
  applications: [],
  directories: [],
  files: [],
  // Shell config (zsh/den) is version-controlled in this dotfiles repo, so we
  // don't back it up here; also skip noise.
  ignore: ['.DS_Store', '*.log', 'zsh', 'den'],
}

export default config
