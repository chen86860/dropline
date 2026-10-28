import {
  HeadContent,
  Scripts,
  createRootRoute,
  useRouterState,
} from '@tanstack/react-router'

import { PostHogAnalytics } from '../lib/posthog'
import appCss from '../styles/app.css?url'

const FONTS =
  'https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Inter+Tight:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap'

/**
 * First visit to an English URL: if the browser asks for Chinese and the
 * visitor has never picked a language, hand them the Chinese page. Runs in
 * <head> before paint, so there is no flash of the wrong language. A manual
 * switch writes the `dl-lang` cookie, after which this never fires again.
 *
 * It covers the landing page and the whole manual — arriving at
 * `/docs/hosts/r2` from a search result should land a Chinese reader on
 * `/zh/docs/hosts/r2`, not on a page they cannot read. Only the English tree is
 * matched, so `/zh/…` is never touched and there is no redirect loop.
 */
const DETECT_LANG = `(function(){try{
var p=location.pathname;
if(p!=="/"&&p!=="/docs"&&p.indexOf("/docs/")!==0)return;
if(document.cookie.indexOf("dl-lang=")>-1)return;
var l=((navigator.languages&&navigator.languages[0])||navigator.language||"").toLowerCase();
if(l.indexOf("zh")!==0)return;
location.replace("/zh"+(p==="/"?"":p)+location.hash);
}catch(e){}})();`

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      {
        name: 'viewport',
        content: 'width=device-width, initial-scale=1, viewport-fit=cover',
      },
      { name: 'theme-color', content: '#f7f8fb' },
    ],
    links: [
      /* The app's own icon — same geometry tools/makeicon.swift renders. */
      { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
      { rel: 'icon', type: 'image/png', sizes: '512x512', href: '/icon-512.png' },
      { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
      { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
      {
        rel: 'preconnect',
        href: 'https://fonts.gstatic.com',
        crossOrigin: 'anonymous',
      },
      { rel: 'stylesheet', href: FONTS },
      { rel: 'stylesheet', href: appCss },
    ],
    scripts: [{ children: DETECT_LANG }],
  }),
  shellComponent: RootDocument,
})

function RootDocument({ children }: { children: React.ReactNode }) {
  const pathname = useRouterState({
    select: (state) => state.location.pathname,
  })
  const lang = pathname.startsWith('/zh') ? 'zh-Hans' : 'en'

  return (
    <html lang={lang}>
      <head>
        <HeadContent />
      </head>
      <body>
        <a
          href="#main"
          className="sr-only z-nav rounded-md bg-accent px-3 py-2 text-sm font-semibold text-accent-ink focus:not-sr-only focus:fixed focus:top-4 focus:left-4"
        >
          {lang === 'en' ? 'Skip to content' : '跳到正文'}
        </a>
        {children}
        <PostHogAnalytics />
        <Scripts />
      </body>
    </html>
  )
}
