#!/usr/bin/env bun
/**
 * git-sync.ts — capture and restore the local-only git work that a macOS wipe
 * would otherwise destroy: unpushed commits, every stash, uncommitted changes,
 * untracked files, and repos that have no remote at all.
 *
 *   rescue   walk ~/Code, bundle each repo's local-only state into iCloud
 *   recover  on a fresh machine, replay those bundles back into the repos
 *
 * Bundles are created with `--all --not --remotes`, so for a repo that already
 * lives on GitHub we only store the delta that isn't on the remote (tiny);
 * a repo with no remote is bundled in full (it exists nowhere else). Nothing is
 * pushed anywhere and the working repos are left untouched.
 *
 * Env overrides (used by the tests): GIT_RESCUE_DIR, CODE_DIR.
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { homedir, tmpdir } from 'node:os'
import { join } from 'node:path'

const HOME = homedir()
const CODE = process.env.CODE_DIR || join(HOME, 'Code')
const ICLOUD = join(HOME, 'Library/Mobile Documents/com~apple~CloudDocs/ts-backups')
const RESCUE = process.env.GIT_RESCUE_DIR || join(ICLOUD, 'git-rescue')

const JUNK_UNTRACKED = new Set(['.DS_Store'])

interface Meta {
  path: string
  branch: string
  head: string
  hasRemote: boolean
  remote: string // origin fetch URL ('' when no remote)
  stashes: string[] // messages, stash@{0} first
  hasWorktree: boolean // uncommitted tracked changes captured
  hasUntracked: boolean
}

/** One row per repo under ~/Code, so recover can rebuild the EXACT layout. */
interface RepoEntry {
  path: string
  remote: string
  hasBundle: boolean
}

function remoteUrl(repo: string): string {
  const direct = git(['remote', 'get-url', 'origin'], repo)
  if (direct.code === 0 && direct.out.trim())
    return direct.out.trim()
  const first = git(['remote'], repo).out.split('\n').filter(Boolean)[0]
  if (first) {
    const u = git(['remote', 'get-url', first], repo)
    if (u.code === 0)
      return u.out.trim()
  }
  return ''
}

function sh(cmd: string[], cwd?: string): { code: number, out: string, err: string } {
  const p = Bun.spawnSync(cmd, { cwd, stdout: 'pipe', stderr: 'pipe' })
  return {
    code: p.exitCode ?? 1,
    out: (p.stdout ? Buffer.from(p.stdout).toString() : '').replace(/\n$/, ''),
    err: (p.stderr ? Buffer.from(p.stderr).toString() : '').replace(/\n$/, ''),
  }
}
const git = (args: string[], cwd: string) => sh(['git', ...args], cwd)
const slugify = (rel: string) => rel.replace(/[/\\]/g, '-')

function findRepos(): string[] {
  const r = sh(['find', CODE, '(', '-name', 'node_modules', '-o', '-name', 'vendor', ')', '-prune', '-o', '-type', 'd', '-name', '.git', '-print'])
  return r.out.split('\n').filter(Boolean).map(p => p.replace(/\/\.git$/, '')).sort()
}

// ── rescue ──────────────────────────────────────────────────────────────────
function rescue(): void {
  mkdirSync(RESCUE, { recursive: true })
  const repos = findRepos()
  const rescued: Meta[] = []
  const allRepos: RepoEntry[] = []
  let skipped = 0

  for (const repo of repos) {
    const rel = repo.startsWith(`${CODE}/`) ? repo.slice(CODE.length + 1) : repo
    const remote = remoteUrl(repo)
    const hasRemote = remote.length > 0

    // Stashes (stash@{0} first), with their messages.
    const stashRaw = git(['stash', 'list', '--format=%H%x1f%gs'], repo).out
    const stashEntries = stashRaw ? stashRaw.split('\n').map((l) => {
      const [sha, ...msg] = l.split('\x1f')
      return { sha, msg: msg.join('\x1f') }
    }) : []

    // Uncommitted TRACKED changes (staged + unstaged) → a dangling commit.
    const worktree = git(['stash', 'create'], repo).out.trim()

    // Commits not on any remote (the unpushed delta).
    const unpushed = hasRemote
      ? git(['log', '--branches', '--not', '--remotes', '--format=%H', '-1'], repo).out.trim()
      : git(['rev-parse', '--verify', '-q', 'HEAD'], repo).out.trim()

    // Untracked, non-junk files (new files never added).
    const untracked = (git(['ls-files', '--others', '--exclude-standard', '-z'], repo).out || '')
      .split('\0').filter(f => f && !JUNK_UNTRACKED.has(f.split('/').pop()!))

    const needBundle = stashEntries.length > 0 || !!worktree || !!unpushed || !hasRemote
    if (!needBundle && untracked.length === 0) {
      // No local-only work, but still record it so recover rebuilds it at the
      // right path. (A repo with no work AND no remote has nothing to restore.)
      if (hasRemote)
        allRepos.push({ path: rel, remote, hasBundle: false })
      skipped++
      continue
    }

    const slug = slugify(rel)
    const dir = join(RESCUE, slug)
    mkdirSync(dir, { recursive: true })

    // Temp refs so the bundle captures stashes + the worktree commit.
    git(['for-each-ref', '--format=%(refname)', 'refs/rescue'], repo).out
      .split('\n').filter(Boolean).forEach(r => git(['update-ref', '-d', r], repo))
    stashEntries.forEach((s, i) => git(['update-ref', `refs/rescue/stash/${i}`, s.sha], repo))
    if (worktree)
      git(['update-ref', 'refs/rescue/worktree', worktree], repo)

    if (needBundle) {
      const bundle = join(dir, 'repo.bundle')
      const args = ['bundle', 'create', bundle, '--all']
      if (hasRemote)
        args.push('--not', '--remotes')
      const r = git(args, repo)
      if (r.code !== 0) {
        // Nothing local-only to bundle after all (e.g. only junk). Keep going.
        console.error(`  ! ${rel}: bundle skipped (${r.err.split('\n')[0]})`)
      }
    }

    // Clean up the temp refs — leave the working repo exactly as we found it.
    git(['for-each-ref', '--format=%(refname)', 'refs/rescue'], repo).out
      .split('\n').filter(Boolean).forEach(r => git(['update-ref', '-d', r], repo))

    if (untracked.length > 0) {
      const listFile = join(tmpdir(), `untracked-${slug}-${untracked.length}.lst`)
      writeFileSync(listFile, `${untracked.join('\0')}\0`)
      const t = sh(['tar', '-czf', join(dir, 'untracked.tar.gz'), '--null', '-T', listFile, '-C', repo])
      rmSync(listFile, { force: true })
      if (t.code !== 0)
        console.error(`  ! ${rel}: untracked tar failed (${t.err.split('\n')[0]})`)
    }

    const meta: Meta = {
      path: rel,
      branch: git(['rev-parse', '--abbrev-ref', 'HEAD'], repo).out.trim() || 'HEAD',
      head: git(['rev-parse', 'HEAD'], repo).out.trim(),
      hasRemote,
      remote,
      stashes: stashEntries.map(s => s.msg),
      hasWorktree: !!worktree,
      hasUntracked: untracked.length > 0,
    }
    writeFileSync(join(dir, 'meta.json'), `${JSON.stringify(meta, null, 2)}\n`)
    rescued.push(meta)
    allRepos.push({ path: rel, remote, hasBundle: existsSync(join(dir, 'repo.bundle')) })

    const tags: string[] = []
    if (unpushed)
      tags.push('unpushed')
    if (stashEntries.length)
      tags.push(`${stashEntries.length} stash`)
    if (worktree)
      tags.push('uncommitted')
    if (untracked.length)
      tags.push(`${untracked.length} untracked`)
    if (!hasRemote)
      tags.push('NO-REMOTE')
    console.warn(`  ✓ ${rel}  [${tags.join(', ')}]`)
  }

  writeFileSync(join(RESCUE, 'manifest.json'), `${JSON.stringify({ rescued, count: rescued.length }, null, 2)}\n`)
  // The full repo list (path + remote) lets recover rebuild your exact ~/Code
  // layout, not just the repos that happened to have local work.
  writeFileSync(join(RESCUE, 'repos.json'), `${JSON.stringify({ repos: allRepos, count: allRepos.length }, null, 2)}\n`)
  console.warn(`\nRescued ${rescued.length} repo(s) with local work → ${RESCUE}`)
  console.warn(`Recorded ${allRepos.length} repo(s) total for layout rebuild.`)
  console.warn(`Skipped ${skipped} repo(s) with nothing local-only to save.`)
}

// ── recover ─────────────────────────────────────────────────────────────────
function recover(): void {
  if (!existsSync(RESCUE)) {
    console.error(`No git-rescue data found at ${RESCUE}. Nothing to recover.`)
    return
  }

  // Drive off the full repo list so we rebuild the exact ~/Code layout; fall
  // back to just the bundled repos if an older rescue didn't write repos.json.
  let entries: RepoEntry[]
  const reposJson = join(RESCUE, 'repos.json')
  if (existsSync(reposJson)) {
    entries = JSON.parse(readFileSync(reposJson, 'utf8')).repos
  }
  else {
    entries = readdirSync(RESCUE, { withFileTypes: true })
      .filter(d => d.isDirectory() && existsSync(join(RESCUE, d.name, 'meta.json')))
      .map((d) => {
        const m: Meta = JSON.parse(readFileSync(join(RESCUE, d.name, 'meta.json'), 'utf8'))
        return { path: m.path, remote: m.remote ?? '', hasBundle: existsSync(join(RESCUE, d.name, 'repo.bundle')) }
      })
  }

  let restored = 0
  let cloned = 0
  const review: string[] = []

  for (const entry of entries) {
    const dest = join(CODE, entry.path)
    const slug = slugify(entry.path)
    const dir = join(RESCUE, slug)
    const bundle = join(dir, 'repo.bundle')

    // Clone to the EXACT original path if missing: from the remote when there
    // is one, otherwise straight from the self-contained bundle.
    if (!existsSync(dest)) {
      mkdirSync(join(dest, '..'), { recursive: true })
      let c
      if (entry.remote)
        c = sh(['git', 'clone', '-q', entry.remote, dest])
      else if (existsSync(bundle))
        c = sh(['git', 'clone', '-q', bundle, dest])
      else
        c = { code: 1, out: '', err: 'no remote and no bundle' }
      if (c.code !== 0) {
        console.error(`  ! ${entry.path}: clone failed (${c.err.split('\n')[0]})`)
        continue
      }
      cloned++
    }

    // A repo with no rescue dir is just a clone (no local work). A repo can
    // have rescue content (untracked files) WITHOUT a bundle, so gate on the
    // meta file, not on hasBundle.
    if (!existsSync(join(dir, 'meta.json'))) {
      console.warn(`  ↺ ${entry.path} (cloned, no local work)`)
      continue
    }

    const meta: Meta = JSON.parse(readFileSync(join(dir, 'meta.json'), 'utf8'))

    // Pull every bundled ref into a private namespace (never touches HEAD).
    if (existsSync(bundle))
      git(['fetch', '-q', bundle, 'refs/*:refs/rescued/*'], dest)

    // Restore unpushed commits: fast-forward each local branch the bundle is
    // ahead of (and create branches that don't exist locally yet).
    const heads = git(['for-each-ref', '--format=%(refname)', 'refs/rescued/heads'], dest).out
      .split('\n').filter(Boolean)
    for (const ref of heads) {
      const branch = ref.replace('refs/rescued/heads/', '')
      const target = git(['rev-parse', ref], dest).out.trim()
      const localRef = `refs/heads/${branch}`
      const exists = git(['rev-parse', '--verify', '-q', localRef], dest).code === 0
      if (!exists) {
        git(['update-ref', localRef, target], dest)
      }
      else {
        const local = git(['rev-parse', localRef], dest).out.trim()
        const ancestor = git(['merge-base', '--is-ancestor', local, target], dest).code === 0
        const isCurrent = git(['rev-parse', '--abbrev-ref', 'HEAD'], dest).out.trim() === branch
        if (local === target) {
          // already up to date
        }
        else if (ancestor && !isCurrent) {
          git(['update-ref', localRef, target], dest)
        }
        else if (ancestor && isCurrent) {
          git(['merge', '--ff-only', target], dest)
        }
        else {
          review.push(`${meta.path}: branch '${branch}' diverged — see refs/rescued/heads/${branch}`)
        }
      }
    }

    // Restore stashes (store in reverse so stash@{0} ends up on top again).
    for (let i = meta.stashes.length - 1; i >= 0; i--) {
      const sha = git(['rev-parse', '--verify', '-q', `refs/rescued/rescue/stash/${i}`], dest).out.trim()
      if (sha)
        git(['stash', 'store', '-m', meta.stashes[i], sha], dest)
    }

    // Restore uncommitted tracked changes back into the working tree.
    if (meta.hasWorktree) {
      const sha = git(['rev-parse', '--verify', '-q', 'refs/rescued/rescue/worktree'], dest).out.trim()
      if (sha) {
        const a = git(['stash', 'apply', '--index', sha], dest)
        if (a.code !== 0) {
          const a2 = git(['stash', 'apply', sha], dest)
          if (a2.code !== 0) {
            git(['stash', 'store', '-m', 'RESCUED: uncommitted changes (apply cleanly with `git stash pop`)', sha], dest)
            review.push(`${meta.path}: uncommitted changes saved as a stash (apply failed) — git stash pop`)
          }
        }
      }
    }

    // Restore untracked files.
    if (meta.hasUntracked && existsSync(join(dir, 'untracked.tar.gz')))
      sh(['tar', '-xzf', join(dir, 'untracked.tar.gz'), '-C', dest])

    // Tidy the namespace (leave only diverged heads for manual review).
    git(['for-each-ref', '--format=%(refname)', 'refs/rescued/rescue', 'refs/rescued/tags'], dest).out
      .split('\n').filter(Boolean).forEach(r => git(['update-ref', '-d', r], dest))

    restored++
    console.warn(`  ✓ ${meta.path}`)
  }

  console.warn(`\nCloned ${cloned} repo(s); restored local work into ${restored} repo(s).`)
  if (review.length) {
    console.warn(`\n⚠️  ${review.length} item(s) need a manual look:`)
    review.forEach(r => console.warn(`   - ${r}`))
  }
}

const cmd = process.argv[2]
if (cmd === 'rescue')
  rescue()
else if (cmd === 'recover')
  recover()
else {
  console.error('usage: git-sync.ts <rescue|recover>')
  process.exit(1)
}
