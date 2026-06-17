import type { BackupConfig } from 'ts-backups'

// App-settings backup config — the successor to the old `.mackup.cfg`.
//
// ts-backups snapshots files/directories (and databases) into `outputPath`. We
// point `outputPath` at iCloud Drive so settings sync across machines, mirroring
// what mackup did. Run with:  bunx ts-backups start
//
// NOTE: ts-backups currently implements backup only (the `start` command).
// "Restore" (symlinking settings back into place on a new machine, like
// `mackup restore`) is a planned feature — for now, copy the relevant snapshot
// back manually.
const HOME = process.env.HOME ?? ''
const ICLOUD = `${HOME}/Library/Mobile Documents/com~apple~CloudDocs`

const config: BackupConfig = {
  verbose: true,
  outputPath: `${ICLOUD}/ts-backups`,
  retention: {
    count: 10, // keep the last 10 snapshots
    maxAge: 90, // ...and drop anything older than 90 days
  },
  databases: [],
  files: [
    {
      name: 'vscode-settings',
      path: `${HOME}/Library/Application Support/Code/User`,
      compress: true,
      include: ['settings.json', 'keybindings.json', 'snippets/**'],
    },
    {
      name: 'cursor-settings',
      path: `${HOME}/Library/Application Support/Cursor/User`,
      compress: true,
      include: ['settings.json', 'keybindings.json', 'snippets/**'],
    },
    {
      name: 'zed-settings',
      path: `${HOME}/.config/zed`,
      compress: true,
    },
    {
      name: 'ssh-config',
      path: `${HOME}/.ssh/config`,
    },
    {
      name: 'gitconfig',
      path: `${HOME}/.gitconfig`,
    },
  ],
}

export default config
