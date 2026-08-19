import { useEffect, useRef, useState } from 'react'

/**
 * Motion for the landing page.
 *
 * Two rules hold throughout: the server-rendered HTML is always the *finished*
 * state, so nothing here is load-bearing for content or for crawlers; and every
 * effect is skipped under `prefers-reduced-motion`. The animation is an
 * enhancement on top of a page that is already complete.
 */

export function prefersReducedMotion() {
  return (
    typeof window !== 'undefined' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  )
}

/**
 * Anything that never scrolls gets the whole page revealed for it.
 *
 * A reveal-on-approach effect hides content until the reader arrives — which is
 * fine for readers, and wrong for everything else that loads this page: search
 * crawlers, link previews, screenshot tools and reader modes do not scroll, and
 * would capture a page of empty sections.
 *
 * So the hidden state is on a timer. The first real scroll disarms it, because
 * a scrolling visitor is a reader and should get the animation. If no scroll
 * has happened by the time the timer expires, whatever is looking at this page
 * is not reading it, and everything is shown at once.
 */
const REVEAL_FALLBACK_MS = 2500

let fallbackInstalled = false

function installRevealFallback() {
  if (fallbackInstalled || typeof window === 'undefined') return
  fallbackInstalled = true

  const timer = window.setTimeout(() => {
    document.documentElement.dataset.revealAll = 'true'
  }, REVEAL_FALLBACK_MS)

  window.addEventListener(
    'scroll',
    () => window.clearTimeout(timer),
    { once: true, passive: true },
  )
}

/**
 * Marks an element as revealed once it comes near the viewport.
 *
 * The hidden state lives in CSS behind `@media (scripting: enabled)`, so with
 * JavaScript off the content is simply visible rather than stuck at zero
 * opacity. The margin is deliberately generous so the reveal has finished
 * before the reader's eye arrives.
 */
export function useReveal<T extends HTMLElement>() {
  const ref = useRef<T>(null)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    if (typeof IntersectionObserver === 'undefined' || prefersReducedMotion()) {
      el.dataset.revealed = 'true'
      return
    }

    installRevealFallback()

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue
          ;(entry.target as HTMLElement).dataset.revealed = 'true'
          observer.unobserve(entry.target)
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0 },
    )

    observer.observe(el)
    return () => observer.disconnect()
  }, [])

  return ref
}

/** One cycle of the hero's upload demo. */
export interface UploadDemo {
  /** 0 idle · 1 transferring · 2 responded · 3 copied */
  phase: number
  /** 0…1, drives the transfer bar */
  progress: number
  /** How much of the URL has been typed into the clipboard line */
  typed: string
}

const TICK = 26
const TYPE_MS = 20
const HOLD_MS = 4200

/**
 * The hero readout, animated: the file lands, the bytes go up, the host
 * answers, the link is typed onto the clipboard. Then it holds, and repeats.
 *
 * It starts — and server-renders — in the *finished* state, which is what makes
 * it safe: the initial HTML shows a completed upload with the full URL, so
 * there is no layout shift on hydration and nothing to see if the animation
 * never runs.
 */
export function useUploadDemo(url: string): UploadDemo {
  const [demo, setDemo] = useState<UploadDemo>({ phase: 3, progress: 1, typed: url })

  useEffect(() => {
    if (prefersReducedMotion()) return

    let cancelled = false
    const timers = new Set<number>()

    function wait(ms: number) {
      return new Promise<void>((resolve) => {
        const timer = window.setTimeout(() => {
          timers.delete(timer)
          resolve()
        }, ms)
        timers.add(timer)
      })
    }

    async function run() {
      while (!cancelled) {
        setDemo({ phase: 0, progress: 0, typed: '' })
        await wait(700)
        if (cancelled) return

        /* Transfer. Eased so it starts quickly and settles — a linear bar reads
           as a fake, because no real transfer is linear. */
        for (let step = 1; step <= 36 && !cancelled; step += 1) {
          const t = step / 36
          setDemo({ phase: 1, progress: 1 - Math.pow(1 - t, 2.4), typed: '' })
          await wait(TICK)
        }
        if (cancelled) return

        setDemo({ phase: 2, progress: 1, typed: '' })
        await wait(420)
        if (cancelled) return

        for (let at = 1; at <= url.length && !cancelled; at += 1) {
          setDemo({ phase: 3, progress: 1, typed: url.slice(0, at) })
          await wait(TYPE_MS)
        }
        if (cancelled) return

        await wait(HOLD_MS)
      }
    }

    void run()

    return () => {
      cancelled = true
      timers.forEach((timer) => window.clearTimeout(timer))
    }
  }, [url])

  return demo
}
