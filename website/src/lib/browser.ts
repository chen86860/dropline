import { useEffect, useState } from 'react'

import type { Lang } from '../content'

export const LANG_COOKIE = 'dl-lang'

/** Remember a manual language choice for a year, so `/` stops guessing. */
export function rememberLang(lang: Lang) {
  if (typeof document === 'undefined') return
  document.cookie = `${LANG_COOKIE}=${lang}; path=/; max-age=31536000; samesite=lax`
  try {
    localStorage.setItem(LANG_COOKIE, lang)
  } catch {
    /* private mode — the cookie is enough */
  }
}

function prefersReducedMotion() {
  return (
    typeof window !== 'undefined' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  )
}

/**
 * Types `text` out once on mount, then stops for good. Server-rendered output
 * and reduced-motion users get the finished string immediately.
 */
export function useTypeOnce(text: string, charMs = 22) {
  const [value, setValue] = useState(text)
  const [done, setDone] = useState(true)

  useEffect(() => {
    if (prefersReducedMotion()) return

    let index = 0
    setValue('')
    setDone(false)

    const timer = window.setInterval(() => {
      index += 1
      setValue(text.slice(0, index))
      if (index >= text.length) {
        window.clearInterval(timer)
        setDone(true)
      }
    }, charMs)

    return () => window.clearInterval(timer)
  }, [text, charMs])

  return { value, done }
}
