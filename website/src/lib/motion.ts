import { useEffect, useRef } from 'react'

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

/**
 * The hero screenshot's pointer tilt.
 *
 * Writes two custom properties on the element the ref lands on; the transform
 * that reads them lives in CSS, so the element is already in its resting state
 * on the server and stays there for anyone on a coarse pointer, on a keyboard,
 * or with reduced motion asked for. The angles are deliberately tiny — this is
 * a sheet of glass catching the light, not a card game.
 */
const TILT_DEG = 3.2

export function useTilt<T extends HTMLElement>() {
  const ref = useRef<T>(null)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    /* Fine pointers only: on a touch screen a `pointermove` is a tap, and the
       tilt would land as a shove the reader never asked for. */
    if (prefersReducedMotion() || !window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
      return
    }

    let frame = 0

    function move(event: PointerEvent) {
      if (frame) return
      frame = window.requestAnimationFrame(() => {
        frame = 0
        const box = el!.getBoundingClientRect()
        const x = (event.clientX - box.left) / box.width - 0.5
        const y = (event.clientY - box.top) / box.height - 0.5
        el!.style.setProperty('--tilt-y', `${(x * TILT_DEG * 2).toFixed(2)}deg`)
        el!.style.setProperty('--tilt-x', `${(-y * TILT_DEG * 2).toFixed(2)}deg`)
      })
    }

    function rest() {
      if (frame) window.cancelAnimationFrame(frame)
      frame = 0
      el!.style.removeProperty('--tilt-x')
      el!.style.removeProperty('--tilt-y')
    }

    el.addEventListener('pointermove', move)
    el.addEventListener('pointerleave', rest)

    return () => {
      rest()
      el.removeEventListener('pointermove', move)
      el.removeEventListener('pointerleave', rest)
    }
  }, [])

  return ref
}
