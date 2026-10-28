
import { AppIcon } from './icons'
import { SHELL } from './SiteHeader'
import { AppLink } from '../lib/links'
import { CONTENT, PATH_FOR, type Lang } from '../content'
import { rememberLang } from '../lib/browser'

/** Ft1 mast-headed footer, shared by the landing page and every docs page. */
export function SiteFooter({ lang }: { lang: Lang }) {
  const t = CONTENT[lang]

  return (
    <footer
      className={`${SHELL} pb-safe border-t border-rule pt-16`}>
      <p className="flex items-center gap-3 font-display text-2xl font-semibold tracking-display text-ink">
        <AppIcon className="size-8" />
        Dropline
      </p>
      <p className="mt-1 max-w-[42ch] text-muted">{t.foot.tagline}</p>

      <ul className="mt-8 flex flex-wrap gap-x-6 gap-y-1">
        {t.foot.links.map((link) => (
          <li key={link.label}>
            {link.href.startsWith('http') || link.href.includes('#') ? (
              <a
                className="inline-flex min-h-9 items-center text-sm whitespace-nowrap text-muted transition-colors duration-micro ease-out hover:text-accent"
                href={link.href}
                rel={link.href.startsWith('http') ? 'noopener' : undefined}
              >
                {link.label}
              </a>
            ) : (
              <AppLink
                className="inline-flex min-h-9 items-center text-sm whitespace-nowrap text-muted transition-colors duration-micro ease-out hover:text-accent"
                href={link.href}
                onClick={() =>
                  link.href === PATH_FOR.zh
                    ? rememberLang('zh')
                    : link.href === PATH_FOR.en
                      ? rememberLang('en')
                      : undefined
                }
              >
                {link.label}
              </AppLink>
            )}
          </li>
        ))}
      </ul>

      <p className="mono-label mt-6 flex flex-wrap gap-x-4 gap-y-1">
        {t.foot.meta.map((part) => (
          <span key={part}>{part}</span>
        ))}
      </p>
    </footer>
  )
}
