import { useEffect, useState } from 'react'

/**
 * Progressive enhancement for the rendered Markdown.
 *
 * The HTML is produced at build time and shipped in the server response, so
 * everything here is strictly additive: without JavaScript the page is still a
 * complete, readable document, it just has no copy buttons and no live rail.
 */

/**
 * Wire up the copy button the Markdown plugin already put in every code block.
 * Delegated from the article element, so it survives navigation between docs
 * without rebinding per button.
 */
export function useCodeCopy(root: React.RefObject<HTMLElement | null>, copied: string, copy: string) {
  useEffect(() => {
    const el = root.current
    if (!el) return

    const timers = new Set<number>()

    /* The build writes the label in English, because the Markdown plugin has no
       idea which language it is compiling. Translate it here, once, on the way
       in — the button does nothing without JavaScript anyway. */
    el.querySelectorAll('[data-copy-label]').forEach((label) => {
      label.textContent = copy
    })

    function onClick(event: MouseEvent) {
      const button = (event.target as HTMLElement | null)?.closest('[data-copy]')
      if (!(button instanceof HTMLElement)) return

      const source = button.closest('.doc-code')?.getAttribute('data-code')
      if (source == null) return

      const label = button.querySelector('[data-copy-label]')
      void navigator.clipboard.writeText(source).then(() => {
        if (!label) return
        label.textContent = copied
        button.dataset.copied = 'true'
        const timer = window.setTimeout(() => {
          label.textContent = copy
          delete button.dataset.copied
          timers.delete(timer)
        }, 1600)
        timers.add(timer)
      })
    }

    el.addEventListener('click', onClick)
    return () => {
      el.removeEventListener('click', onClick)
      timers.forEach((timer) => window.clearTimeout(timer))
    }
  }, [root, copied, copy])
}

/**
 * The id of the heading the reader is currently under, for the on-page rail.
 *
 * Deliberately not "the topmost visible heading": that flickers when a short
 * section scrolls past. Instead it tracks the last heading whose top has
 * crossed the reading line, which is what a reader would say they are "in".
 */
export function useActiveHeading(ids: string[]) {
  const [active, setActive] = useState(ids[0] ?? '')

  useEffect(() => {
    if (!ids.length) return

    const headings = ids
      .map((id) => document.getElementById(id))
      .filter((el): el is HTMLElement => el !== null)

    if (!headings.length) return

    function update() {
      /* The line sits a third of the way down, below the sticky header. */
      const line = window.innerHeight / 3

      let current = headings[0].id
      for (const heading of headings) {
        if (heading.getBoundingClientRect().top <= line) current = heading.id
        else break
      }

      /* At the very bottom the last heading wins, even if it never crossed the
         line — otherwise a short final section can never become active. */
      if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 2) {
        current = headings[headings.length - 1].id
      }

      setActive(current)
    }

    update()
    window.addEventListener('scroll', update, { passive: true })
    window.addEventListener('resize', update)
    return () => {
      window.removeEventListener('scroll', update)
      window.removeEventListener('resize', update)
    }
  }, [ids])

  return active
}

/** True once the component has mounted in a browser — gates portals and shortcuts. */
export function useMounted() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])
  return mounted
}
