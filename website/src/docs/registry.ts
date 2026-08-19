/**
 * The docs, as data.
 *
 * Markdown is compiled to HTML by the build (`plugins/markdown.ts`), so a docs
 * route renders synchronously with no parser, no loader and no fetch. That is
 * what makes the whole manual server-rendered: crawlers and assistants get the
 * complete text of every page in the first response.
 *
 * The glob is **per language**, and each language has its own entry module
 * (`en.ts`, `zh.ts`). A reader of the English docs never downloads the Chinese
 * ones, and the landing page — which imports only `routes.ts` — downloads
 * neither.
 */

import type { Lang } from '../content'
import { DOC_GROUPS } from './nav'
import { DOCS_ROOT, docHref } from './routes'

export { DOCS_ROOT, docHref }

export interface TocEntry {
  depth: number
  id: string
  text: string
}

export interface Doc {
  lang: Lang
  /** `''` for the index, otherwise `guide/templates` — no leading slash. */
  slug: string
  /** The route this doc lives at: `/docs/guide/templates`, `/zh/docs/…`. */
  href: string
  title: string
  description: string
  toc: TocEntry[]
  html: string
  /** Prose with the markup stripped, for search. */
  text: string
  /** Repo-relative path, for the "edit this page" link. */
  source: string
}

export interface DocModule {
  meta: { title: string; description: string }
  toc: TocEntry[]
  html: string
  text: string
}

/** One language's compiled Markdown, keyed by slug. */
export class DocSet {
  private readonly docs = new Map<string, Doc>()

  constructor(
    readonly lang: Lang,
    modules: Record<string, DocModule>,
  ) {
    for (const [path, mod] of Object.entries(modules)) {
      /* ./content/<lang>/<...slug>.md */
      const match = /^\.\/content\/[^/]+\/(.+)\.md$/.exec(path)
      if (!match) continue

      const slug = match[1] === 'index' ? '' : match[1].replace(/\/index$/, '')

      this.docs.set(slug, {
        lang,
        slug,
        href: docHref(lang, slug),
        title: mod.meta.title || slug,
        description: mod.meta.description || '',
        toc: mod.toc,
        html: mod.html,
        text: mod.text,
        source: `website/src/docs/content/${lang}/${match[1]}.md`,
      })
    }
  }

  get(slug: string) {
    return this.docs.get(slug)
  }

  has(slug: string) {
    return this.docs.has(slug)
  }

  /** Every doc in sidebar order — which is also the order they are meant to be read in. */
  ordered(): Doc[] {
    const ordered: Doc[] = []
    const index = this.get('')
    if (index) ordered.push(index)

    for (const group of DOC_GROUPS) {
      for (const slug of group.items) {
        const doc = this.get(slug)
        if (doc) ordered.push(doc)
      }
    }
    return ordered
  }

  /** The pages either side of this one, for the footer pager. */
  siblings(slug: string) {
    const ordered = this.ordered()
    const at = ordered.findIndex((doc) => doc.slug === slug)
    if (at === -1) return { prev: undefined, next: undefined }
    return { prev: ordered[at - 1], next: ordered[at + 1] }
  }

  /**
   * The sidebar: groups with their pages resolved to titles. Any slug listed in
   * `nav.ts` without a matching file is skipped rather than rendered as a dead
   * link, so a half-finished translation degrades quietly.
   */
  sidebar() {
    return DOC_GROUPS.map((group) => ({
      id: group.id,
      label: group.label[this.lang],
      items: group.items
        .map((slug) => this.get(slug))
        .filter((doc): doc is Doc => doc !== undefined)
        .map((doc) => ({ slug: doc.slug, href: doc.href, title: doc.title })),
    })).filter((group) => group.items.length > 0)
  }
}
