import { CONTENT, DOWNLOAD_DMG, PATH_FOR, REPO, type Lang } from '../content'

/**
 * The domain the site is served from. Drives canonical, hreflang, Open Graph
 * and every URL inside the structured data — set it before deploying.
 */
export const SITE_URL = 'https://dropline.emmmm.dev'

/**
 * Structured data. Two graphs, both grounded in facts the page already states:
 *
 * - `SoftwareApplication` is the one that matters here. It tells search engines
 *   this is a free macOS app rather than an article, and it is still eligible
 *   for rich treatment.
 * - `FAQPage` no longer produces FAQ rich results for sites like this one —
 *   Google narrowed those to government and health domains in 2023. It is kept
 *   because it is still read by assistants and AI search, and it costs nothing.
 *
 * Every answer here is the same string rendered into the page, which is the
 * condition for the markup being valid at all.
 */
function structuredData(lang: Lang) {
  const t = CONTENT[lang]
  const url = `${SITE_URL}${PATH_FOR[lang]}`
  const inLanguage = lang === 'zh' ? 'zh-Hans' : 'en'

  return {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'SoftwareApplication',
        '@id': `${SITE_URL}#app`,
        name: 'Dropline',
        description: t.meta.description,
        url,
        applicationCategory: 'UtilitiesApplication',
        operatingSystem: 'macOS 13.0 or later',
        processorRequirements: 'Apple Silicon',
        downloadUrl: DOWNLOAD_DMG,
        softwareHelp: REPO,
        image: `${SITE_URL}/icon-512.png`,
        inLanguage,
        license: `${REPO}/blob/main/LICENSE`,
        isAccessibleForFree: true,
        author: {
          '@type': 'Person',
          name: 'chen86860',
          url: 'https://github.com/chen86860',
        },
        offers: {
          '@type': 'Offer',
          price: '0',
          priceCurrency: 'USD',
        },
      },
      {
        '@type': 'FAQPage',
        '@id': `${url}#faq`,
        inLanguage,
        mainEntity: t.faq.items.map((item) => ({
          '@type': 'Question',
          name: item.q,
          acceptedAnswer: { '@type': 'Answer', text: item.a },
        })),
      },
    ],
  }
}

/** Title, description, canonical, hreflang, Open Graph and JSON-LD for one language. */
export function headFor(lang: Lang) {
  const { meta } = CONTENT[lang]
  const url = `${SITE_URL}${PATH_FOR[lang]}`

  return {
    meta: [
      { title: meta.title },
      { name: 'description', content: meta.description },
      { property: 'og:type', content: 'website' },
      { property: 'og:site_name', content: 'Dropline' },
      { property: 'og:title', content: meta.title },
      { property: 'og:description', content: meta.description },
      { property: 'og:url', content: url },
      { property: 'og:locale', content: lang === 'zh' ? 'zh_CN' : 'en_US' },
      {
        property: 'og:locale:alternate',
        content: lang === 'zh' ? 'en_US' : 'zh_CN',
      },
      { property: 'og:image', content: `${SITE_URL}/icon-512.png` },
      { property: 'og:image:alt', content: 'The Dropline app icon' },
      { name: 'twitter:card', content: 'summary' },
    ],
    links: [
      { rel: 'canonical', href: url },
      {
        rel: 'alternate',
        hrefLang: 'en',
        href: `${SITE_URL}${PATH_FOR.en}`,
      },
      {
        rel: 'alternate',
        hrefLang: 'zh-Hans',
        href: `${SITE_URL}${PATH_FOR.zh}`,
      },
      {
        rel: 'alternate',
        hrefLang: 'x-default',
        href: `${SITE_URL}${PATH_FOR.en}`,
      },
    ],
    scripts: [
      {
        type: 'application/ld+json',
        children: JSON.stringify(structuredData(lang)),
      },
    ],
  }
}
