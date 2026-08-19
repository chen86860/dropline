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
