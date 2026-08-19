import { PATH_FOR, REPO, type Lang } from '../content'
import { DOCS_UI } from '../docs/nav'
import type { Doc, DocSet } from '../docs/registry'
import { DOCS_ROOT } from '../docs/routes'
import { SITE_URL } from './head'

/**
 * Head tags for one documentation page.
 *
 * Same contract as the landing page's `headFor`: title, description, canonical,
 * the hreflang triple, Open Graph, and JSON-LD grounded in what the page
 * actually renders. The structured data here is a `TechArticle` inside the
 * site's `SoftwareApplication`, plus a `BreadcrumbList` — both of which
 * describe a manual page rather than a product page.
 */
export function docsHeadFor(lang: Lang, doc: Doc, docs: DocSet) {
  const ui = DOCS_UI[lang]
  const url = `${SITE_URL}${doc.href}`
  const inLanguage = lang === 'zh' ? 'zh-Hans' : 'en'
  const title = doc.slug ? `${doc.title} — Dropline ${ui.label}` : `Dropline ${ui.label} — ${doc.title}`

  /* Only claim a translation exists when it does; a hreflang pointing at a
     missing page is worse than no hreflang at all. */
  const other: Lang = lang === 'en' ? 'zh' : 'en'
  const alternates: { lang: Lang; href: string }[] = [{ lang, href: doc.href }]
  if (doc.slug === '' || docs.has(doc.slug)) {
    alternates.push({ lang: other, href: `${DOCS_ROOT[other]}${doc.slug ? `/${doc.slug}` : ''}` })
  }

  const section = docs
    .sidebar()
    .find((group) => group.items.some((item) => item.slug === doc.slug))

  const breadcrumb = [
    { name: 'Dropline', item: `${SITE_URL}${PATH_FOR[lang]}` },
    { name: ui.label, item: `${SITE_URL}${DOCS_ROOT[lang]}` },
    ...(section ? [{ name: section.label, item: `${SITE_URL}${DOCS_ROOT[lang]}` }] : []),
    ...(doc.slug ? [{ name: doc.title, item: url }] : []),
  ]

  const structuredData = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'TechArticle',
        '@id': `${url}#article`,
        headline: doc.title,
        description: doc.description,
        url,
        inLanguage,
        isPartOf: { '@id': `${SITE_URL}${DOCS_ROOT[lang]}#docs` },
        about: { '@id': `${SITE_URL}#app` },
        author: { '@type': 'Person', name: 'chen86860', url: 'https://github.com/chen86860' },
        license: `${REPO}/blob/main/LICENSE`,
      },
      {
        '@type': 'Collection',
        '@id': `${SITE_URL}${DOCS_ROOT[lang]}#docs`,
        name: `Dropline ${ui.label}`,
        description: ui.tagline,
        url: `${SITE_URL}${DOCS_ROOT[lang]}`,
        inLanguage,
      },
      {
        '@type': 'BreadcrumbList',
        '@id': `${url}#breadcrumb`,
        itemListElement: breadcrumb.map((crumb, index) => ({
          '@type': 'ListItem',
          position: index + 1,
          name: crumb.name,
          item: crumb.item,
        })),
      },
    ],
  }

  return {
    meta: [
      { title },
      { name: 'description', content: doc.description },
      { property: 'og:type', content: 'article' },
      { property: 'og:site_name', content: 'Dropline' },
      { property: 'og:title', content: title },
      { property: 'og:description', content: doc.description },
      { property: 'og:url', content: url },
      { property: 'og:locale', content: lang === 'zh' ? 'zh_CN' : 'en_US' },
      { property: 'og:image', content: `${SITE_URL}/icon-512.png` },
      { property: 'og:image:alt', content: 'The Dropline app icon' },
      { name: 'twitter:card', content: 'summary' },
    ],
    links: [
      { rel: 'canonical', href: url },
      ...alternates.map((alternate) => ({
        rel: 'alternate',
        hrefLang: alternate.lang === 'zh' ? 'zh-Hans' : 'en',
        href: `${SITE_URL}${alternate.href}`,
      })),
      {
        rel: 'alternate',
        hrefLang: 'x-default',
        href: `${SITE_URL}${DOCS_ROOT.en}${doc.slug ? `/${doc.slug}` : ''}`,
      },
    ],
    scripts: [{ type: 'application/ld+json', children: JSON.stringify(structuredData) }],
  }
}

/** Head tags for the 404 inside the docs — indexable pages only, please. */
export function docsNotFoundHead(lang: Lang) {
  const ui = DOCS_UI[lang]
  return {
    meta: [
      { title: `${ui.notFoundTitle} — Dropline ${ui.label}` },
      { name: 'robots', content: 'noindex' },
    ],
  }
}
