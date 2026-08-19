/**
 * Markdown → ES module, at build time.
 *
 * Every `.md` file under `src/docs/content` is compiled once, during the build,
 * into a module that exports finished HTML. Nothing about Markdown survives
 * into the bundle: no parser, no highlighter, no runtime cost on the Worker.
 * The docs routes are therefore server-rendered as plain HTML strings, which is
 * the whole point — crawlers get the full text of every page in the first
 * response, exactly as they do for the landing page.
 *
 * The module shape is:
 *
 *   export const meta = { title, description, … }   // frontmatter
 *   export const toc  = [{ depth, id, text }]       // h2/h3, for the rail
 *   export const html = "<h2 id=…>…"                // rendered body
 *   export const text = "…"                         // plain text, for search
 */

import { readFileSync } from 'node:fs'

import MarkdownIt, { type Token } from 'markdown-it'
import { createHighlighter, type Highlighter } from 'shiki'
import type { Plugin } from 'vite'

/** Languages the docs actually use. Anything else falls back to plain text. */
const LANGS = [
  'bash',
  'diff',
  'html',
  'ini',
  'json',
  'jsonc',
  'swift',
  'text',
  'toml',
  'ts',
  'tsx',
  'xml',
  'yaml',
]

/** One theme — the site is light, code blocks are the graphite beat. */
const THEME = 'github-dark-default'

let highlighterPromise: Promise<Highlighter> | undefined

function getHighlighter() {
  highlighterPromise ??= createHighlighter({ themes: [THEME], langs: LANGS })
  return highlighterPromise
}

export interface DocMeta {
  title: string
  description: string
  [key: string]: string
}

export interface TocEntry {
  depth: number
  id: string
  text: string
}

/**
 * Frontmatter, deliberately tiny: `key: value` lines between two `---` fences.
 * The docs never need lists or nesting, and a real YAML parser in the build
 * would be a dependency bought for nothing.
 */
function parseFrontmatter(source: string): { meta: DocMeta; body: string } {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(source)
  if (!match) return { meta: { title: '', description: '' }, body: source }

  const meta: Record<string, string> = {}
  for (const line of match[1].split(/\r?\n/)) {
    const at = line.indexOf(':')
    if (at === -1) continue
    const key = line.slice(0, at).trim()
    let value = line.slice(at + 1).trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    meta[key] = value
  }

  return {
    meta: { title: '', description: '', ...meta },
    body: source.slice(match[0].length),
  }
}

/** GitHub-style anchor: lowercase, spaces to dashes, punctuation dropped. CJK kept. */
function slugify(text: string) {
  return (
    text
      .trim()
      .toLowerCase()
      .replace(/<[^>]+>/g, '')
      .replace(/[\s]+/g, '-')
      // keep letters, numbers, dashes and CJK; drop the rest
      .replace(/[^\p{Letter}\p{Number}\-_]/gu, '')
      .replace(/-{2,}/g, '-')
      .replace(/^-|-$/g, '') || 'section'
  )
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

/**
 * Shiki paints both a background and a foreground onto `<pre>` as inline
 * styles. The docs want the site's own graphite for the background — but the
 * foreground has to survive, because an unhighlighted block (`text`, and any
 * language Shiki does not know) carries no per-token spans at all and would
 * otherwise inherit the page's dark body colour onto a dark card.
 *
 * So: drop `background-color`, keep `color`. The block is then wrapped in a
 * figure carrying the language label and the copy button's hook, with
 * `data-code` holding the raw source so copying never has to walk the DOM.
 */
function renderCodeBlock(highlighter: Highlighter, code: string, rawLang: string) {
  const lang = LANGS.includes(rawLang) ? rawLang : 'text'
  const highlighted = highlighter
    .codeToHtml(code, { lang, theme: THEME })
    .replace(/(<pre[^>]*?style=")([^"]*)"/, (_all, head: string, style: string) => {
      const kept = style
        .split(';')
        .map((rule) => rule.trim())
        .filter((rule) => rule.startsWith('color:'))
        .join(';')
      return `${head}${kept}"`
    })
    .replace(/<pre/, '<pre class="doc-code__pre"')

  return [
    `<figure class="doc-code" data-code="${escapeHtml(code)}">`,
    `<figcaption class="doc-code__bar">`,
    `<span class="doc-code__lang">${escapeHtml(rawLang || 'text')}</span>`,
    `<button type="button" class="doc-code__copy" data-copy>`,
    `<span data-copy-label>Copy</span>`,
    `</button>`,
    `</figcaption>`,
    highlighted,
    `</figure>`,
  ].join('')
}

/**
 * A heading's plain text.
 *
 * `token.content` would be the raw Markdown, so a heading like
 * ``About `{{base}}` `` would reach the on-page rail with its backticks still
 * attached. Walking the inline children instead yields what the reader sees.
 */
function headingText(inline: Token | undefined) {
  if (inline?.type !== 'inline' || !inline.children) return inline?.content ?? ''
  return inline.children
    .filter((child) => child.type === 'text' || child.type === 'code_inline')
    .map((child) => child.content)
    .join('')
    .trim()
}

/** Strip the rendered HTML back to prose, for the search index. */
function toPlainText(html: string) {
  return html
    .replace(/<figure class="doc-code"[\s\S]*?<\/figure>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim()
}

export async function compileMarkdown(source: string) {
  const highlighter = await getHighlighter()
  const { meta, body } = parseFrontmatter(source)
  const toc: TocEntry[] = []
  const seen = new Map<string, number>()

  const md = new MarkdownIt({
    html: true,
    linkify: true,
    typographer: false,
    highlight: () => '', // replaced wholesale by the fence rule below
  })

  md.renderer.rules.fence = (tokens, index) => {
    const token = tokens[index]
    return renderCodeBlock(highlighter, token.content, (token.info || '').trim())
  }

  /* Headings get a stable id and a permalink anchor, and h2/h3 also feed the
     on-page rail. Doing it in the renderer keeps ids and rail in lockstep. */
  md.renderer.rules.heading_open = (tokens, index) => {
    const token = tokens[index]
    const depth = Number(token.tag.slice(1))
    const text = headingText(tokens[index + 1])

    const base = slugify(text)
    const count = seen.get(base) ?? 0
    seen.set(base, count + 1)
    const id = count === 0 ? base : `${base}-${count}`

    if (depth === 2 || depth === 3) toc.push({ depth, id, text })

    return `<${token.tag} id="${id}" class="doc-heading">`
  }

  md.renderer.rules.heading_close = (tokens, index) => {
    const token = tokens[index]
    const depth = Number(token.tag.slice(1))
    if (depth !== 2 && depth !== 3) return `</${token.tag}>`
    const id = toc[toc.length - 1]?.id ?? ''
    return `<a class="doc-heading__link" href="#${id}" aria-hidden="true" tabindex="-1">#</a></${token.tag}>`
  }

  /* Tables scroll inside their own box rather than pushing the page sideways. */
  md.renderer.rules.table_open = () => '<div class="doc-table"><table>'
  md.renderer.rules.table_close = () => '</table></div>'

  /* Off-site links open in a new tab and carry the usual rel guard. */
  const defaultLinkOpen =
    md.renderer.rules.link_open ??
    ((tokens, index, options, _env, self) => self.renderToken(tokens, index, options))

  md.renderer.rules.link_open = (tokens, index, options, env, self) => {
    const href = String(tokens[index].attrGet('href') ?? '')
    if (/^https?:\/\//.test(href)) {
      tokens[index].attrSet('target', '_blank')
      tokens[index].attrSet('rel', 'noopener noreferrer')
    }
    return defaultLinkOpen(tokens, index, options, env, self)
  }

  const html = md.render(body)

  return { meta, toc, html, text: toPlainText(html) }
}

const MD_FILE = /\.md($|\?)/

export function markdown(): Plugin {
  return {
    name: 'dropline:markdown',
    enforce: 'pre',

    async transform(source, id) {
      if (!MD_FILE.test(id)) return
      if (id.includes('?raw') || id.includes('?url')) return

      const { meta, toc, html, text } = await compileMarkdown(source)

      return {
        code: [
          `export const meta = ${JSON.stringify(meta)};`,
          `export const toc = ${JSON.stringify(toc)};`,
          `export const html = ${JSON.stringify(html)};`,
          `export const text = ${JSON.stringify(text)};`,
          `export default { meta, toc, html, text };`,
        ].join('\n'),
        map: null,
      }
    },

    /** Editing a doc reloads the page — the module graph has no other consumer. */
    handleHotUpdate({ file, server }) {
      if (!file.endsWith('.md')) return
      server.hot.send({ type: 'full-reload' })
    },
  }
}

/** Compile one file from disk. Used by the sitemap plugin, which needs frontmatter. */
export async function compileFile(path: string) {
  return compileMarkdown(readFileSync(path, 'utf8'))
}
