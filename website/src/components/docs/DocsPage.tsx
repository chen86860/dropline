import { useCallback, useRef, useState } from 'react'

import { DocsSearch, useSearchShortcut } from './DocsSearch'
import { REPO, type Lang } from '../../content'
import { DOCS_UI } from '../../docs/nav'
import type { Doc, DocSet } from '../../docs/registry'
import { DOCS_ROOT } from '../../docs/routes'
import { useActiveHeading, useCodeCopy } from '../../lib/docs-client'
import { AppLink } from '../../lib/links'
import { ArrowIcon, ChevronIcon, CloseIcon, MenuIcon } from '../icons'
import { SiteFooter } from '../SiteFooter'
import { SHELL_WIDE, SearchTrigger, SiteHeader, docsNavLinks } from '../SiteHeader'

/**
 * The docs shell: sidebar, article, on-page rail.
 *
 * Everything a crawler needs — the full body of the page, the sidebar's links
 * and the pager — is in the server-rendered HTML. The client adds the search
 * dialog, the copy buttons and the live rail highlight, none of which the page
 * depends on to be readable.
 */
export function DocsPage({ lang, docs, doc }: { lang: Lang; docs: DocSet; doc: Doc }) {
  const ui = DOCS_UI[lang]
  const sidebar = docs.sidebar()
  const { prev, next } = docs.siblings(doc.slug)

  const [searchOpen, setSearchOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const openSearch = useCallback(() => setSearchOpen(true), [])
  useSearchShortcut(openSearch)

  const article = useRef<HTMLElement>(null)
  useCodeCopy(article, ui.copied, ui.copy)

  const rail = doc.toc.filter((entry) => entry.depth === 2 || entry.depth === 3)
  const active = useActiveHeading(rail.map((entry) => entry.id))

  /* The language toggle keeps the reader on the same page where a translation
     exists, and drops them at the other manual's index where it does not. */
  const langHref: Record<Lang, string> = {
    en: doc.slug && lang === 'zh' ? `${DOCS_ROOT.en}/${doc.slug}` : DOCS_ROOT.en,
    zh: doc.slug && lang === 'en' ? `${DOCS_ROOT.zh}/${doc.slug}` : DOCS_ROOT.zh,
  }

  return (
    <>
      <SiteHeader
        lang={lang}
        wide
        links={docsNavLinks(lang)}
        langHref={langHref}
        slot={<SearchTrigger label={ui.searchOpen} onOpen={openSearch} />}
        before={
          <button
            type="button"
            className="-ml-1 inline-grid size-10 shrink-0 cursor-pointer place-items-center rounded-sm text-muted transition-colors duration-micro ease-out hover:text-ink lg:hidden"
            aria-label={ui.menu}
            aria-expanded={menuOpen}
            onClick={() => setMenuOpen((open) => !open)}
          >
            {menuOpen ? <CloseIcon /> : <MenuIcon />}
          </button>
        }
      />

      <div
        className={`${SHELL_WIDE} grid grid-cols-[minmax(0,1fr)] items-start gap-x-10 lg:grid-cols-[15rem_minmax(0,1fr)] xl:grid-cols-[15rem_minmax(0,1fr)_13rem]`}
      >
        {/* ── Sidebar ─────────────────────────────────────────────────── */}
        <nav
          aria-label={ui.sidebar}
          className={[
            'border-b border-rule py-6 lg:sticky lg:top-[calc(var(--banner-height))] lg:max-h-[calc(100dvh-var(--banner-height))]',
            'lg:overflow-y-auto lg:border-b-0 lg:py-10 lg:pr-4',
            menuOpen ? '' : 'max-lg:hidden',
          ].join(' ')}
        >
          <SidebarLink href={DOCS_ROOT[lang]} current={doc.slug === ''} onNavigate={() => setMenuOpen(false)}>
            {docs.get('')?.title ?? ui.label}
          </SidebarLink>

          {sidebar.map((group) => (
            <div key={group.id} className="mt-7 first:mt-4">
              <p className="mono-label mb-2">{group.label}</p>
              <ul className="border-l border-rule">
                {group.items.map((item) => (
                  <li key={item.slug}>
                    <SidebarLink
                      href={item.href}
                      current={item.slug === doc.slug}
                      nested
                      onNavigate={() => setMenuOpen(false)}
                    >
                      {item.title}
                    </SidebarLink>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>

        {/* ── The page itself ─────────────────────────────────────────── */}
        <main className="min-w-0 py-10 lg:py-14">
          <nav aria-label={ui.breadcrumb} className="mb-6 flex flex-wrap items-center gap-1.5">
            <AppLink
              href={DOCS_ROOT[lang]}
              className="mono-label transition-colors duration-micro ease-out hover:text-accent"
            >
              {ui.label}
            </AppLink>
            {sectionOf(sidebar, doc.slug) ? (
              <>
                <ChevronIcon className="size-3 text-neutral" />
                <span className="mono-label">{sectionOf(sidebar, doc.slug)}</span>
              </>
            ) : null}
          </nav>

          <article
            ref={article}
            className="doc-prose"
            dangerouslySetInnerHTML={{ __html: doc.html }}
          />

          {/* On-page rail, inline below the text where there is no third column */}
          {rail.length > 2 ? (
            <details className="mt-12 rounded-md border border-rule bg-paper-2 p-4 xl:hidden">
              <summary className="mono-label cursor-pointer">{ui.onThisPage}</summary>
              <ul className="mt-3 grid gap-1.5">
                {rail.map((entry) => (
                  <li key={entry.id} style={{ paddingInlineStart: entry.depth === 3 ? '1rem' : 0 }}>
                    <a
                      href={`#${entry.id}`}
                      className="text-sm text-muted transition-colors duration-micro ease-out hover:text-accent"
                    >
                      {entry.text}
                    </a>
                  </li>
                ))}
              </ul>
            </details>
          ) : null}

          <div className="mt-12 flex flex-wrap items-center gap-x-6 gap-y-2 border-t border-rule pt-6">
            <a
              className="inline-flex items-center gap-2 text-sm text-muted transition-colors duration-micro ease-out hover:text-accent"
              href={`${REPO}/blob/main/${doc.source}`}
              rel="noopener"
            >
              {ui.edit}
              <ArrowIcon className="size-3.5" />
            </a>
          </div>

          {prev || next ? (
            <nav className="mt-6 grid gap-3 sm:grid-cols-2">
              {prev ? <Pager doc={prev} label={ui.prev} direction="prev" /> : <span />}
              {next ? <Pager doc={next} label={ui.next} direction="next" /> : null}
            </nav>
          ) : null}
        </main>

        {/* ── On-page rail, the third column ──────────────────────────── */}
        {rail.length > 2 ? (
          <aside
            aria-label={ui.onThisPage}
            className="sticky top-[calc(var(--banner-height)+2.5rem)] hidden py-14 xl:block"
          >
            <p className="mono-label">{ui.onThisPage}</p>
            <ul className="mt-3 grid gap-1.5 border-l border-rule">
              {rail.map((entry) => (
                <li key={entry.id}>
                  <a
                    href={`#${entry.id}`}
                    aria-current={entry.id === active ? 'true' : undefined}
                    className={[
                      'block border-l-2 py-0.5 text-sm transition-colors duration-micro ease-out',
                      entry.depth === 3 ? 'pl-6' : 'pl-3',
                      entry.id === active
                        ? '-ml-px border-accent text-accent'
                        : '-ml-px border-transparent text-muted hover:text-ink',
                    ].join(' ')}
                  >
                    {entry.text}
                  </a>
                </li>
              ))}
            </ul>
          </aside>
        ) : null}
      </div>

      <div className="border-t border-rule">
        <SiteFooter lang={lang} wide />
      </div>

      <DocsSearch lang={lang} docs={docs} open={searchOpen} onClose={() => setSearchOpen(false)} />
    </>
  )
}

function sectionOf(sidebar: ReturnType<DocSet['sidebar']>, slug: string) {
  return sidebar.find((group) => group.items.some((item) => item.slug === slug))?.label
}

function SidebarLink({
  href,
  current,
  nested = false,
  onNavigate,
  children,
}: {
  href: string
  current: boolean
  nested?: boolean
  onNavigate: () => void
  children: React.ReactNode
}) {
  return (
    <AppLink
      href={href}
      onClick={onNavigate}
      aria-current={current ? 'page' : undefined}
      className={[
        'block py-1.5 text-sm transition-colors duration-micro ease-out',
        nested ? '-ml-px border-l-2 pl-3' : '',
        current
          ? nested
            ? 'border-accent font-medium text-accent'
            : 'font-medium text-accent'
          : nested
            ? 'border-transparent text-muted hover:border-rule-2 hover:text-ink'
            : 'text-muted hover:text-ink',
      ].join(' ')}
    >
      {children}
    </AppLink>
  )
}

function Pager({
  doc,
  label,
  direction,
}: {
  doc: Doc
  label: string
  direction: 'prev' | 'next'
}) {
  return (
    <AppLink
      href={doc.href}
      className={[
        'group grid gap-1 rounded-md border border-rule bg-paper-2 px-4 py-3',
        'transition-colors duration-micro ease-out hover:border-accent',
        direction === 'next' ? 'text-right sm:col-start-2' : '',
      ].join(' ')}
    >
      <span className="mono-label">{label}</span>
      <span className="text-base font-medium text-ink transition-colors duration-micro ease-out group-hover:text-accent">
        {doc.title}
      </span>
    </AppLink>
  )
}

/** Shown for a docs URL that does not resolve to a page. */
export function DocsNotFound({ lang, docs }: { lang: Lang; docs: DocSet }) {
  const ui = DOCS_UI[lang]

  return (
    <>
      <SiteHeader lang={lang} wide links={docsNavLinks(lang)} />
      <main className={`${SHELL_WIDE} grid place-items-start gap-6 py-28`}>
        <p className="mono-label">404</p>
        <h1 className="max-w-[18ch] text-3xl font-semibold">{ui.notFoundTitle}</h1>
        <p className="max-w-[60ch] text-md text-muted">{ui.notFoundBody}</p>
        <AppLink className="btn btn-primary" href={DOCS_ROOT[lang]}>
          {ui.notFoundCta}
          <ArrowIcon />
        </AppLink>

        <ul className="mt-6 grid gap-1">
          {docs.ordered().map((doc) => (
            <li key={doc.slug}>
              <AppLink
                href={doc.href}
                className="text-sm text-muted transition-colors duration-micro ease-out hover:text-accent"
              >
                {doc.title}
              </AppLink>
            </li>
          ))}
        </ul>
      </main>
      <div className="border-t border-rule">
        <SiteFooter lang={lang} wide />
      </div>
    </>
  )
}
