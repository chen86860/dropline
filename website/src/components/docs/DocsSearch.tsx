import { useNavigate } from '@tanstack/react-router'
import { useEffect, useMemo, useRef, useState } from 'react'

import type { Lang } from '../../content'
import { DOCS_UI } from '../../docs/nav'
import type { DocSet } from '../../docs/registry'
import { SearchIcon } from '../icons'

interface Hit {
  href: string
  title: string
  /** The group this page sits in, so two similarly named pages are separable. */
  section: string
  /** A snippet around the first match, or the page description. */
  excerpt: string
  score: number
}

/**
 * Search across one language's manual.
 *
 * Twenty-odd pages is small enough that scoring every one on every keystroke is
 * imperceptible, so there is no index to build, no worker and no dependency —
 * the docs are already in memory because the page was rendered from them.
 */
function search(docs: DocSet, query: string): Hit[] {
  const terms = query
    .toLowerCase()
    .split(/\s+/)
    .filter((term) => term.length > 0)

  if (!terms.length) return []

  const sections = new Map<string, string>()
  for (const group of docs.sidebar()) {
    for (const item of group.items) sections.set(item.slug, group.label)
  }

  const hits: Hit[] = []

  for (const doc of docs.ordered()) {
    const title = doc.title.toLowerCase()
    const description = doc.description.toLowerCase()
    const body = doc.text.toLowerCase()
    const headings = doc.toc.map((entry) => entry.text.toLowerCase()).join(' · ')

    let score = 0
    let firstAt = -1

    for (const term of terms) {
      /* Weighted by where the term appears: a title match is what the reader
         meant; a body match is a maybe. Every term has to appear somewhere,
         which is what makes a two-word query narrow rather than widen. */
      let termScore = 0
      if (title.includes(term)) termScore += 100
      if (headings.includes(term)) termScore += 40
      if (description.includes(term)) termScore += 20

      const at = body.indexOf(term)
      if (at !== -1) {
        termScore += 10
        if (firstAt === -1) firstAt = at
      }

      if (termScore === 0) {
        score = 0
        break
      }
      score += termScore
    }

    if (score === 0) continue

    hits.push({
      href: doc.href,
      title: doc.title,
      section: sections.get(doc.slug) ?? DOCS_UI[doc.lang].label,
      excerpt: firstAt === -1 ? doc.description : excerptAround(doc.text, firstAt),
      score,
    })
  }

  return hits.sort((a, b) => b.score - a.score).slice(0, 8)
}

function excerptAround(text: string, at: number) {
  const start = Math.max(0, at - 60)
  const slice = text.slice(start, start + 160).trim()
  return `${start > 0 ? '…' : ''}${slice}${start + 160 < text.length ? '…' : ''}`
}

export function DocsSearch({
  lang,
  docs,
  open,
  onClose,
}: {
  lang: Lang
  docs: DocSet
  open: boolean
  onClose: () => void
}) {
  const ui = DOCS_UI[lang]
  const navigate = useNavigate()
  const [query, setQuery] = useState('')
  const [cursor, setCursor] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)

  const hits = useMemo(() => search(docs, query), [docs, query])

  useEffect(() => setCursor(0), [query])

  useEffect(() => {
    if (!open) return
    setQuery('')
    inputRef.current?.focus()

    /* The page behind must not scroll while the dialog is up. */
    const previous = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = previous
    }
  }, [open])

  if (!open) return null

  function go(hit: Hit | undefined) {
    if (!hit) return
    onClose()
    /* Same reason as `AppLink`: a docs path is computed, so the route union
       cannot see it, but the router resolves it fine. */
    void navigate({ to: hit.href as never })
  }

  function onKeyDown(event: React.KeyboardEvent) {
    if (event.key === 'Escape') {
      event.preventDefault()
      onClose()
    } else if (event.key === 'ArrowDown') {
      event.preventDefault()
      setCursor((at) => (hits.length ? (at + 1) % hits.length : 0))
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      setCursor((at) => (hits.length ? (at - 1 + hits.length) % hits.length : 0))
    } else if (event.key === 'Enter') {
      event.preventDefault()
      go(hits[cursor])
    }
  }

  return (
    <div
      className="fixed inset-0 z-modal flex items-start justify-center bg-backdrop px-4 pt-[12vh] backdrop-blur-[2px]"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={ui.search}
        className="search-panel w-full max-w-[36rem] overflow-hidden rounded-md border border-rule bg-paper shadow-lift"
        onClick={(event) => event.stopPropagation()}
        onKeyDown={onKeyDown}
      >
        <div className="flex items-center gap-3 border-b border-rule px-4">
          <SearchIcon className="text-neutral" />
          <input
            ref={inputRef}
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={ui.searchPlaceholder}
            aria-label={ui.search}
            className="min-h-14 flex-1 bg-transparent text-md text-ink outline-none placeholder:text-neutral"
          />
          <kbd className="rounded-[4px] border border-rule px-1.5 font-mono text-2xs text-neutral">
            esc
          </kbd>
        </div>

        {query.trim() ? (
          hits.length ? (
            <ul className="max-h-[52vh] overflow-y-auto">
              {hits.map((hit, index) => (
                <li key={hit.href}>
                  <a
                    href={hit.href}
                    onMouseEnter={() => setCursor(index)}
                    onClick={(event) => {
                      event.preventDefault()
                      go(hit)
                    }}
                    aria-current={index === cursor ? 'true' : undefined}
                    className={[
                      'block border-b border-rule px-4 py-3 transition-colors duration-micro ease-out',
                      index === cursor ? 'bg-accent-wash' : '',
                    ].join(' ')}
                  >
                    <span className="mono-label">{hit.section}</span>
                    <span className="mt-0.5 block text-base font-medium text-ink">
                      {hit.title}
                    </span>
                    <span className="mt-0.5 block line-clamp-2 text-sm text-muted">
                      {hit.excerpt}
                    </span>
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <p className="px-4 py-8 text-center text-sm text-muted">{ui.searchEmpty}</p>
          )
        ) : null}

        <p className="mono-label px-4 py-3">{ui.searchHint}</p>
      </div>
    </div>
  )
}

/** ⌘K / ctrl-K anywhere in the docs, and `/` when not already typing. */
export function useSearchShortcut(onOpen: () => void) {
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      const typing =
        event.target instanceof HTMLElement &&
        (event.target.isContentEditable ||
          ['INPUT', 'TEXTAREA', 'SELECT'].includes(event.target.tagName))

      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        onOpen()
      } else if (event.key === '/' && !typing) {
        event.preventDefault()
        onOpen()
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onOpen])
}
