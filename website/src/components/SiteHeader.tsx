import { useEffect, useState, type ReactNode } from 'react'
import { useRouterState } from '@tanstack/react-router'

import { AppIcon, AppleIcon, MenuToggleIcon, SearchIcon } from './icons'
import { AppLink } from '../lib/links'
import { CONTENT, DOWNLOAD_DMG, LANGS, PATH_FOR, REPO, type Lang } from '../content'
import { DOCS_ROOT } from '../docs/routes'
import { rememberLang } from '../lib/browser'

const LANG_NAME: Record<Lang, string> = { en: 'EN', zh: '中文' }

/** One measure for the whole site: the landing page and the docs share it, so
    navigating between them never shifts the content edges. */
export const SHELL = 'mx-auto w-full max-w-wide px-4 sm:px-6 xl:px-12'

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
  links,
  langHref,
  slot,
  before,
}: {
  lang: Lang
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
  const pathname = useRouterState({ select: (state) => state.location.pathname })

  /* Pages with their own leading control (the docs sidebar toggle) bring
     their own small-screen navigation; everything else gets this menu. */
  const [menuOpen, setMenuOpen] = useState(false)
  const hasMenu = !before

  useEffect(() => {
    if (!menuOpen) return
    const close = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMenuOpen(false)
    }
    window.addEventListener('keydown', close)
    return () => window.removeEventListener('keydown', close)
  }, [menuOpen])

  /** A route link is current when the reader is on it or inside it. */
  const isCurrent = (href: string) =>
    !href.startsWith('#') &&
    !href.startsWith('http') &&
    href !== PATH_FOR[lang] &&
    (pathname === href || pathname.startsWith(`${href}/`))

  return (
    <header className="sticky top-0 z-nav pt-3">
      <div className={SHELL}>
        {/* Floats just off the top edge; at full width it shrinks to its
            contents, below that it spans the gutter. */}
        <div className="mx-auto flex min-h-14 w-full items-center gap-3 rounded-xl border border-rule bg-paper/80 px-3 shadow-whisper backdrop-blur-md xl:w-fit xl:gap-4">
          {before}

          <a
            href={PATH_FOR[lang]}
            className="mr-auto inline-flex items-center gap-2 font-display text-md font-semibold tracking-display whitespace-nowrap text-ink xl:mr-4"
          >
            <AppIcon className="size-6" />
            Dropline
          </a>

          <nav className="mr-2 hidden items-center gap-6 xl:flex" aria-label={t.nav.navLabel}>
            {navLinks.map((link) => (
              <NavLink key={link.href} href={link.href} current={isCurrent(link.href)}>
                {link.label}
              </NavLink>
            ))}
          </nav>

          {slot}

          <div
            className="inline-flex shrink-0 overflow-hidden rounded-md border border-rule"
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
            className="btn btn-primary shrink-0 text-sm"
            href={DOWNLOAD_DMG}
            rel="noopener"
            aria-label={t.nav.download}
          >
            <AppleIcon />
            <span className="max-sm:sr-only">{t.nav.download}</span>
          </a>

          {hasMenu ? (
            <button
              type="button"
              className="-mr-1 inline-grid size-10 shrink-0 cursor-pointer place-items-center rounded-md text-muted transition-colors duration-micro ease-out hover:text-ink xl:hidden"
              aria-label={t.nav.navLabel}
              aria-expanded={menuOpen}
              aria-controls="site-menu"
              onClick={() => setMenuOpen((open) => !open)}
            >
              <MenuToggleIcon open={menuOpen} />
            </button>
          ) : null}
        </div>
      </div>

      {hasMenu ? (
        <nav
          id="site-menu"
          aria-label={t.nav.navLabel}
          data-open={menuOpen ? '' : undefined}
          inert={!menuOpen}
          className="mobile-menu fixed inset-x-0 top-(--banner-height) bottom-0 bg-paper xl:hidden"
        >
          <ul className={`${SHELL} grid gap-2 pt-8`}>
            {navLinks.map((link) => (
              <li key={link.href}>
                <NavLink
                  href={link.href}
                  current={isCurrent(link.href)}
                  onClick={() => setMenuOpen(false)}
                  large
                >
                  {link.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}
    </header>
  )
}

function NavLink({
  href,
  current,
  large = false,
  onClick,
  children,
}: {
  href: string
  current: boolean
  large?: boolean
  onClick?: () => void
  children: ReactNode
}) {
  const className = [
    'whitespace-nowrap transition-colors duration-micro ease-out',
    large ? 'block border-b border-rule py-4 font-display text-2xl font-semibold' : 'py-2 text-sm',
    current ? 'font-medium text-ink' : large ? 'text-ink-2 hover:text-accent' : 'text-muted hover:text-ink',
  ].join(' ')

  return href.startsWith('#') || href.startsWith('http') ? (
    <a
      href={href}
      rel={href.startsWith('http') ? 'noopener' : undefined}
      className={className}
      onClick={onClick}
    >
      {children}
    </a>
  ) : (
    <AppLink
      href={href}
      className={className}
      aria-current={current ? 'page' : undefined}
      onClick={onClick}
    >
      {children}
    </AppLink>
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
      className="mr-1 inline-flex min-h-10 shrink-0 cursor-pointer items-center gap-2 rounded-md border border-rule bg-paper-2 px-3 text-sm text-muted transition-colors duration-micro ease-out hover:border-rule-2 hover:text-ink"
    >
      <SearchIcon />
      <span className="max-lg:sr-only">{label}</span>
      <kbd className="ml-2 hidden rounded-sm border border-rule bg-paper px-2 font-mono text-2xs text-neutral lg:inline-block">
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
