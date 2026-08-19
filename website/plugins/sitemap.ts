/**
 * sitemap.xml, generated from the routes that actually exist.
 *
 * The landing page has two URLs and the manual has one per Markdown file per
 * language, which is far too many to keep correct by hand — a stale sitemap is
 * worse than none, because it advertises 404s. Emitting it from the file tree
 * means the file cannot disagree with the site.
 */

import { readdirSync, statSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

import type { Plugin } from 'vite'

/** Keep in step with `SITE_URL` in `src/lib/head.ts`. */
const SITE_URL = 'https://dropline.emmmm.dev'

const CONTENT_DIR = join(process.cwd(), 'src', 'docs', 'content')

interface Entry {
  path: string
  priority: string
  /** The same page in the other language, when there is one. */
  alternates: { hreflang: string; href: string }[]
}

function walk(dir: string): string[] {
  const found: string[] = []
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    if (statSync(full).isDirectory()) found.push(...walk(full))
    else if (name.endsWith('.md')) found.push(full)
  }
  return found
}

function slugsFor(lang: string) {
  const dir = join(CONTENT_DIR, lang)
  try {
    return walk(dir).map((file) =>
      relative(dir, file).replace(/\.md$/, '').split(sep).join('/'),
    )
  } catch {
    return []
  }
}

function docPath(lang: string, slug: string) {
  const root = lang === 'en' ? '/docs' : '/zh/docs'
  return slug === 'index' ? root : `${root}/${slug}`
}

function collect(): Entry[] {
  const entries: Entry[] = []

  const landing = [
    { lang: 'en', path: '/' },
    { lang: 'zh', path: '/zh' },
  ]

  for (const page of landing) {
    entries.push({
      path: page.path,
      priority: page.lang === 'en' ? '1.0' : '0.9',
      alternates: [
        { hreflang: 'en', href: '/' },
        { hreflang: 'zh-Hans', href: '/zh' },
        { hreflang: 'x-default', href: '/' },
      ],
    })
  }

  const en = new Set(slugsFor('en'))
  const zh = new Set(slugsFor('zh'))

  for (const [lang, slugs] of [
    ['en', en],
    ['zh', zh],
  ] as const) {
    for (const slug of [...slugs].sort()) {
      const translated = lang === 'en' ? zh.has(slug) : en.has(slug)
      const alternates = [
        { hreflang: lang === 'en' ? 'en' : 'zh-Hans', href: docPath(lang, slug) },
      ]
      if (translated) {
        const other = lang === 'en' ? 'zh' : 'en'
        alternates.push({
          hreflang: other === 'en' ? 'en' : 'zh-Hans',
          href: docPath(other, slug),
        })
      }
      if (en.has(slug)) {
        alternates.push({ hreflang: 'x-default', href: docPath('en', slug) })
      }

      entries.push({
        path: docPath(lang, slug),
        priority: slug === 'index' ? '0.8' : '0.7',
        alternates,
      })
    }
  }

  return entries
}

function render(entries: Entry[]) {
  const urls = entries
    .map((entry) => {
      const alternates = entry.alternates
        .map(
          (alternate) =>
            `    <xhtml:link rel="alternate" hreflang="${alternate.hreflang}" href="${SITE_URL}${alternate.href}"/>`,
        )
        .join('\n')

      return [
        '  <url>',
        `    <loc>${SITE_URL}${entry.path}</loc>`,
        alternates,
        '    <changefreq>monthly</changefreq>',
        `    <priority>${entry.priority}</priority>`,
        '  </url>',
      ].join('\n')
    })
    .join('\n')

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!-- Generated at build time by plugins/sitemap.ts — do not edit by hand. -->',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"',
    '        xmlns:xhtml="http://www.w3.org/1999/xhtml">',
    urls,
    '</urlset>',
    '',
  ].join('\n')
}

export function sitemap(): Plugin {
  return {
    name: 'dropline:sitemap',

    /* Emitted into the client build, which is what Cloudflare serves as static
       assets. The dev server gets the same bytes from the middleware below. */
    generateBundle() {
      if (this.environment.name !== 'client') return
      this.emitFile({
        type: 'asset',
        fileName: 'sitemap.xml',
        source: render(collect()),
      })
    },

    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (req.url?.split('?')[0] !== '/sitemap.xml') return next()
        res.setHeader('Content-Type', 'application/xml')
        res.end(render(collect()))
      })
    },
  }
}
