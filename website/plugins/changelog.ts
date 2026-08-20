/**
 * The changelog, as a docs page — read from the repository, not copied into it.
 *
 * `CHANGELOG.md` at the repo root is the single source of release notes: the
 * Sparkle appcast and the GitHub release body are both cut from it by
 * `tools/changelog.py`, and the in-app update dialog shows the same text. The
 * website reads that very file, so the page cannot drift from what a user sees
 * when the app offers them an update.
 *
 * The result is handed to the docs registry as an ordinary compiled page, so
 * the changelog gets the sidebar, the search index, the pager and the head tags
 * for free — see `src/docs/en.ts`.
 */

import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

import type { Plugin } from 'vite'

import { compileMarkdown } from './markdown'

/** `website/plugins` → the repository root. */
const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..')

const VIRTUAL = 'virtual:dropline-changelog/'
const RESOLVED = '\0' + VIRTUAL

interface Source {
  /** Repo-relative, which is also what the "edit this page" link wants. */
  file: string
  title: string
  description: string
  intro: string
}

const SOURCES: Record<string, Source> = {
  en: {
    file: 'CHANGELOG.md',
    title: 'Changelog',
    description: 'Every release of Dropline and what changed in it.',
    intro:
      'These are the release notes that ship with the app — the update dialog and the GitHub ' +
      'release show the same text. Dates are release dates.',
  },
  zh: {
    file: 'CHANGELOG.zh-CN.md',
    title: '更新日志',
    description: 'Dropline 每个版本的变更内容。',
    intro:
      '这里是随 App 一同发布的更新说明 —— 更新弹窗和 GitHub Release 用的是同一份文本。' +
      '日期为发布日期。',
  },
}

/**
 * Both files open with a title and a few paragraphs telling the maintainer how
 * to cut a release. A reader of the website wants neither, so the page starts
 * at the first version heading.
 */
function releaseNotes(markdown: string) {
  const at = markdown.search(/^## /m)
  return at === -1 ? '' : markdown.slice(at)
}

/**
 * `## [1.5.0] - 2026-08-20` reads better on a page as `## 1.5.0 — 2026-08-20`.
 * The brackets are a Keep a Changelog convention for a link reference, and this
 * file has no link references.
 */
function tidyHeadings(markdown: string) {
  return markdown.replace(
    /^## \[(\d+\.\d+\.\d+)\]\s*-\s*(\S+)[ \t]*$/gm,
    (_all, version: string, date: string) => `## ${version} — ${date}`,
  )
}

function pageSource(lang: string) {
  const source = SOURCES[lang]
  const body = tidyHeadings(releaseNotes(readFileSync(join(REPO_ROOT, source.file), 'utf8')))
  return [
    '---',
    `title: ${source.title}`,
    `description: ${source.description}`,
    '---',
    '',
    `# ${source.title}`,
    '',
    source.intro,
    '',
    body,
  ].join('\n')
}

export function changelog(): Plugin {
  return {
    name: 'dropline:changelog',
    enforce: 'pre',

    resolveId(id) {
      if (id.startsWith(VIRTUAL) && SOURCES[id.slice(VIRTUAL.length)]) return '\0' + id
      return undefined
    },

    async load(id) {
      if (!id.startsWith(RESOLVED)) return undefined
      const lang = id.slice(RESOLVED.length)
      const source = SOURCES[lang]
      if (!source) return undefined

      const { meta, toc, html, text } = await compileMarkdown(pageSource(lang))

      /* Only the version headings go in the on-page rail. Each release has
         three or four subsections under it, and listing those too would make
         the rail longer than some of the entries it points at. */
      const versions = toc.filter((entry) => entry.depth === 2)

      return [
        `export const meta = ${JSON.stringify(meta)};`,
        `export const toc = ${JSON.stringify(versions)};`,
        `export const html = ${JSON.stringify(html)};`,
        `export const text = ${JSON.stringify(text)};`,
        `export const source = ${JSON.stringify(source.file)};`,
        `export default { meta, toc, html, text, source };`,
      ].join('\n')
    },

    /* The files sit outside the Vite root, so they are not watched by default
       and editing one would otherwise leave the dev server showing stale notes. */
    configureServer(server) {
      const watched = new Map<string, string>()
      for (const [lang, source] of Object.entries(SOURCES)) {
        const path = join(REPO_ROOT, source.file)
        watched.set(path, lang)
        server.watcher.add(path)
      }

      server.watcher.on('change', (file) => {
        const lang = watched.get(file)
        if (!lang) return

        /* The page is server-rendered, so dropping it from the client graph
           alone would leave the SSR render holding the previous text — every
           environment has to be told. Importers go too: `en.ts` and `zh.ts`
           read the module eagerly, so they have the old value baked in. */
        for (const environment of Object.values(server.environments)) {
          const module = environment.moduleGraph.getModuleById(RESOLVED + lang)
          if (!module) continue
          environment.moduleGraph.invalidateModule(module)
          for (const importer of module.importers) {
            environment.moduleGraph.invalidateModule(importer)
          }
        }
        server.hot.send({ type: 'full-reload' })
      })
    },
  }
}
