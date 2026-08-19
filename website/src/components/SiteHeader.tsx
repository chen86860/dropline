import type { ReactNode } from 'react'

import { AppIcon, AppleIcon, SearchIcon } from './icons'
import { AppLink } from '../lib/links'
import { CONTENT, DOWNLOAD_DMG, LANGS, PATH_FOR, REPO, type Lang } from '../content'
import { DOCS_ROOT } from '../docs/routes'
import { rememberLang } from '../lib/browser'

const LANG_NAME: Record<Lang, string> = { en: 'EN', zh: '中文' }

export const SHELL = 'mx-auto w-full max-w-page px-[clamp(1.125rem,4vw,3rem)]'
export const SHELL_WIDE = 'mx-auto w-full max-w-wide px-[clamp(1.125rem,4vw,3rem)]'

/**
 * One header for the whole site.
 *
 * The landing page passes its in-page anchors; the docs pass a search trigger
 * and their own sibling link. Everything else — brand, language toggle,
 * download button — is identical, and identical here means one implementation
 * rather than two that drift.
 */
export function SiteHeader({
  lang,
  wide = false,
  links,
  langHref,
  slot,
  before,
}: {
  lang: Lang
  /** Docs run wider than the landing page's 74rem measure. */
  wide?: boolean
  links?: { label: string; href: string }[]
  /** Where the language toggle points; defaults to the other language's home. */
  langHref?: Record<Lang, string>
  /** Extra control between the links and the language toggle — the search button. */
  slot?: ReactNode
  /** Leading control, before the brand — the mobile sidebar toggle. */
  before?: ReactNode
}) {
  const t = CONTENT[lang]
  const navLinks = links ?? t.nav.links
  const target = langHref ?? PATH_FOR

  return (
    <header className="sticky top-0 z-nav border-b border-rule bg-paper/85 backdrop-blur-[10px]">
      <div
        className={`${wide ? SHELL_WIDE : SHELL} flex min-h-[60px] items-center gap-3 xl:min-h-[68px]`}
      >
        {before}

        <a
          href={PATH_FOR[lang]}
          className="mr-auto inline-flex items-center gap-2 font-display text-md font-semibold tracking-display whitespace-nowrap text-ink"
        >
          <AppIcon className="size-5" />
          Dropline
        </a>

        <nav className="mr-2 hidden items-center gap-6 xl:flex" aria-label={t.nav.navLabel}>
          {navLinks.map((link) =>
            link.href.startsWith('#') || link.href.startsWith('http') ? (
              <a
                key={link.href}
                href={link.href}
                rel={link.href.startsWith('http') ? 'noopener' : undefined}
                className="py-2 text-sm whitespace-nowrap text-muted transition-colors duration-micro ease-out hover:text-ink"
              >
                {link.label}
              </a>
            ) : (
              <AppLink
                key={link.href}
                href={link.href}
                className="py-2 text-sm whitespace-nowrap text-muted transition-colors duration-micro ease-out hover:text-ink"
              >
                {link.label}
              </AppLink>
            ),
          )}
        </nav>

        {slot}

        <div
          className="inline-flex shrink-0 overflow-hidden rounded-sm border border-rule"
          role="group"
          aria-label={t.nav.langLabel}
        >
          {LANGS.map((code, index) => (
            <AppLink
              key={code}
              href={target[code]}
              hrefLang={code === 'zh' ? 'zh-Hans' : 'en'}
              aria-current={code === lang ? 'true' : undefined}
              onClick={() => rememberLang(code)}
              className={[
                'inline-grid min-h-10 min-w-10 place-items-center px-2 font-mono text-2xs tracking-mono whitespace-nowrap',
                'transition-colors duration-micro ease-out',
                index > 0 ? 'border-l border-rule' : '',
                code === lang ? 'bg-accent-wash text-accent-deep' : 'text-muted hover:text-ink',
              ].join(' ')}
            >
              {LANG_NAME[code]}
            </AppLink>
          ))}
        </div>

        {/* Below 30rem the label is dropped rather than allowed to wrap or push
            the bar past the viewport — the Apple mark carries it. */}
        <a
          className="btn btn-primary min-h-10 shrink-0 px-3 text-sm sm:px-4"
          href={DOWNLOAD_DMG}
          rel="noopener"
          aria-label={t.nav.download}
        >
          <AppleIcon />
          <span className="max-sm:sr-only">{t.nav.download}</span>
        </a>
      </div>
    </header>
  )
}

/** The docs header's search trigger — a real button, keyboard shortcut hinted. */
export function SearchTrigger({
  label,
  onOpen,
}: {
  label: string
  onOpen: () => void
}) {
  return (
    <button
      type="button"
      onClick={onOpen}
      aria-label={label}
      className="mr-1 inline-flex min-h-10 shrink-0 cursor-pointer items-center gap-2 rounded-sm border border-rule bg-paper-2 px-3 text-sm text-muted transition-colors duration-micro ease-out hover:border-rule-2 hover:text-ink"
    >
      <SearchIcon />
      <span className="max-lg:sr-only">{label}</span>
      <kbd className="ml-2 hidden rounded-[4px] border border-rule bg-paper px-1.5 font-mono text-2xs text-neutral lg:inline-block">
        ⌘K
      </kbd>
    </button>
  )
}

/** Docs nav links, in each language. Kept beside the header that renders them. */
export function docsNavLinks(lang: Lang) {
  const t = CONTENT[lang]
  return [
    { label: t.nav.overview, href: PATH_FOR[lang] },
    { label: t.nav.docs, href: DOCS_ROOT[lang] },
    { label: 'GitHub', href: REPO },
  ]
}
