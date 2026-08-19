/**
 * Docs URLs, and nothing else.
 *
 * Deliberately free of any `import.meta.glob`: the landing page's header links
 * to the docs, and pulling the registry in here would drag every compiled
 * Markdown page into the landing page's bundle.
 */

import type { Lang } from '../content'

/** The root of the docs tree in each language. */
export const DOCS_ROOT: Record<Lang, string> = {
  en: '/docs',
  zh: '/zh/docs',
}

export function docHref(lang: Lang, slug: string) {
  return slug ? `${DOCS_ROOT[lang]}/${slug}` : DOCS_ROOT[lang]
}
