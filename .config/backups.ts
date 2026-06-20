/**
 * .config/backups.ts — what gets synced off this machine so a fresh macOS
 * install can be brought back to life without re-authenticating everything.
 *
 * Driven by ts-backups (https://github.com/stacksjs/ts-backups), the mackup
 * successor. Snapshots are written to iCloud Drive — NOT to this git repo,
 * which is public. Nothing secret ever touches git; it rides iCloud instead,
 * which persists across a wipe and syncs to every machine.
 *
 *   Snapshot here:   bun run backup      (alias: ./bin/dotsync start)
 *   Restore there:   bun run restore     (alias: ./bin/dotsync restore --overwrite)
 *
 * Each entry becomes its own timestamped, retained snapshot, so you can
 * restore one thing in isolation:  bun run restore --only ssh --overwrite
 *
 * Resolved by bunfig as `backups.ts` because ./bin/dotsync runs ts-backups
 * with this `.config/` directory as the working directory.
 *
 * The `import type` below is erased at runtime (bun strips type-only imports),
 * so this file loads even when `ts-backups` isn't installed as a dependency —
 * it just gives editor autocompletion when it is.
 */
import type { BackupConfig } from 'ts-backups'
import { homedir } from 'node:os'
import { join } from 'node:path'

const HOME = homedir()

/** iCloud Drive — survives a macOS reinstall and syncs across machines. */
const ICLOUD = join(HOME, 'Library/Mobile Documents/com~apple~CloudDocs')
const outputPath = join(ICLOUD, 'ts-backups')

/** Directories we never want to walk into when collecting project secrets. */
const HEAVY_DIRS = [
  'node_modules',
  '.git',
  'vendor',
  'dist',
  'build',
  'out',
  '.next',
  '.nuxt',
  '.output',
  '.cache',
  '.turbo',
  'coverage',
  'zig-out',
  'zig-cache',
  '.zig-cache',
  'target',
  'Pods',
  '.venv',
  'venv',
  '__pycache__',
  // Generated infra/build output — these duplicate real .env files as
  // synthesized artifacts, so skip them.
  'cdk.out',
  '.serverless',
  '.terraform',
  '.vercel',
  '.wrangler',
]

// Exclude each heavy dir at any depth, plus the (rare) top-level case.
const excludeHeavy = HEAVY_DIRS.flatMap(d => [`**/${d}`, d])

// Editor `User` folders hold gigabytes of state next to the few files we want;
// don't descend into any of it. The bare name matters: these sit at the TOP of
// `User/`, so a `**/`-prefixed pattern (which requires a parent slash) wouldn't
// match them — ts-backups would walk the whole multi-GB tree for nothing.
const editorHeavy = [
  'globalStorage',
  'workspaceStorage',
  'History',
  'logs',
  'CachedData',
  'Backups',
].flatMap(d => [d, `**/${d}`])

const config: BackupConfig = {
  verbose: true,
  outputPath,
  retention: {
    // Keep a generous history per entry; prune anything older than ~3 months.
    count: 10,
    maxAge: 90,
  },
  databases: [],
  files: [
    // ── Credentials & profile ───────────────────────────────────────────
    // SSH keys, config, known_hosts. preserveMetadata keeps the 0600 perms
    // that ssh refuses to run without.
    {
      name: 'ssh',
      path: join(HOME, '.ssh'),
      compress: true,
      preserveMetadata: true,
      exclude: ['**/*.sock', '**/S.*'],
    },
    // AWS credentials/config.
    {
      name: 'aws',
      path: join(HOME, '.aws'),
      compress: true,
      preserveMetadata: true,
    },
    // GitHub CLI token + hosts.
    {
      name: 'gh',
      path: join(HOME, '.config/gh'),
      compress: true,
    },
    // GitHub Copilot token.
    {
      name: 'github-copilot',
      path: join(HOME, '.config/github-copilot'),
      compress: true,
      optional: true,
    },
    // npm / registry auth tokens.
    {
      name: 'npmrc',
      path: join(HOME, '.npmrc'),
      optional: true,
    },
    // Docker registry auth.
    {
      name: 'docker-config',
      path: join(HOME, '.docker/config.json'),
      optional: true,
    },
    // Composer global auth (auth.json), if present.
    {
      name: 'composer',
      path: join(HOME, '.config/composer'),
      compress: true,
      optional: true,
      exclude: ['**/cache/**', '**/cache'],
    },

    // ── Git identity ────────────────────────────────────────────────────
    {
      name: 'gitconfig',
      path: join(HOME, '.gitconfig'),
    },
    {
      name: 'git-config-dir',
      path: join(HOME, '.config/git'),
      compress: true,
    },

    // ── Editor & app settings (the mackup role) ─────────────────────────
    {
      name: 'vscode-settings',
      path: join(HOME, 'Library/Application Support/Code/User'),
      compress: true,
      optional: true,
      include: ['settings.json', 'keybindings.json', 'snippets/**'],
      exclude: editorHeavy,
    },
    {
      name: 'cursor-settings',
      path: join(HOME, 'Library/Application Support/Cursor/User'),
      compress: true,
      optional: true,
      include: ['settings.json', 'keybindings.json', 'snippets/**'],
      exclude: editorHeavy,
    },
    {
      name: 'zed',
      path: join(HOME, '.config/zed'),
      compress: true,
      optional: true,
      exclude: ['**/logs/**', '**/db/**', '**/*.log'],
    },
    {
      name: 'raycast',
      path: join(HOME, '.config/raycast'),
      compress: true,
      optional: true,
      // Skip `extensions/` — 400MB of reinstallable extension code. We only
      // want the actual settings (config.json) and AI presets. The bare name
      // matters: `extensions` sits at the root of ~/.config/raycast, so a
      // `**/`-prefixed pattern (which needs a parent slash) wouldn't match it.
      exclude: ['extensions', '**/extensions'],
    },

    // ── Project secrets ─────────────────────────────────────────────────
    // Every real .env across ~/Code (recursively), preserving each file's
    // relative path on restore. Tracked-in-git example files are skipped —
    // they're already version-controlled and carry no secrets.
    {
      name: 'project-envs',
      path: join(HOME, 'Code'),
      compress: true,
      include: ['**/.env', '**/.env.*', '.env', '.env.*'],
      exclude: [
        ...excludeHeavy,
        // Both forms: `**/x` misses a root-level ~/Code/x (no parent slash).
        '**/.env.example',
        '.env.example',
        '**/.env.sample',
        '.env.sample',
        '**/.env.dist',
        '.env.dist',
        '**/.env.template',
        '.env.template',
      ],
    },
  ],
}

export default config
