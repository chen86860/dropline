# Dropline — website

The landing page for [Dropline](../README.md). TanStack Start + React 19 +
Tailwind v4, server-rendered on Cloudflare Workers.

```bash
pnpm install
pnpm dev        # http://localhost:3000
pnpm build      # dist/client + dist/server
pnpm typecheck
```

## Bilingual routing

| Route | Language |
| --- | --- |
| `/` | English (also the `x-default` for search engines) |
| `/zh` | 简体中文 |

Both routes render the same `<Landing>` component; every string lives in
[`src/content.ts`](src/content.ts), so a copy change touches one file.

Language is resolved in three steps:

1. **Auto** — a small script in `<head>` ([`src/routes/__root.tsx`](src/routes/__root.tsx))
   runs on `/` only. If `navigator.language` starts with `zh` and the visitor
   has never chosen, it replaces the URL with `/zh` before first paint, so
   there is no flash of the wrong language.
2. **Manual** — the `EN / 中文` toggle in the nav (and the language link in the
   footer) navigates between the two routes.
3. **Remembered** — a manual choice writes a `dl-lang` cookie for a year, after
   which step 1 never fires again.

Because each language is a real, server-rendered URL, both are crawlable and
shareable. `hreflang` and canonical tags are emitted from
[`src/lib/head.ts`](src/lib/head.ts) — **set `SITE_URL` there to the real
domain before going live**, since it drives the canonical and Open Graph tags.

## Design system

`src/styles/tokens.css` is a Tailwind v4 `@theme` block holding the whole
system — colours (OKLCH), the three font families, the type scale, easings and
motion buckets. Markup references tokens by name (`bg-paper`, `text-ink`,
`duration-micro`); no component hard-codes a colour or a font. The file is
portable: drop it into another Tailwind v4 project and the system comes with
it. `src/styles/app.css` holds only base rules and the handful of component
classes Tailwind has no utility for.

## SEO

Both routes are server-rendered, so the full text — including every FAQ answer
— is in the initial HTML. `<details>` keeps answers collapsed visually while
leaving them in the DOM, which is what crawlers read.

Emitted per route from [`src/lib/head.ts`](src/lib/head.ts): title, description,
canonical, the `hreflang` triple (`en` / `zh-Hans` / `x-default`), Open Graph,
and a JSON-LD `@graph` with two nodes.

- **`SoftwareApplication`** — the one that earns rich treatment here. Declares
  a free macOS 13+ app with its download URL, licence and author.
- **`FAQPage`** — kept because assistants and AI search read it, but be aware
  Google narrowed FAQ rich results to government and health sites in 2023, so
  **this will not produce FAQ snippets in Google Search.** The real benefit is
  indexable long-tail content answering questions people search for.

Every question and answer in the JSON-LD is byte-identical to what the page
renders; that parity is a requirement for the markup to be valid at all. If you
edit `faq` in `src/content.ts`, both update together — there is no second copy.

`public/robots.txt` and `public/sitemap.xml` hard-code the domain. Change them
alongside `SITE_URL` when the real domain is settled.

## The app icon

The site uses the real Dropline icon, in two forms:

- **`<AppIcon>`** in [`src/components/icons.tsx`](src/components/icons.tsx) — the
  same geometry [`tools/makeicon.swift`](../tools/makeicon.swift) draws, as
  inline SVG, so it stays crisp at 20px in the nav and 64px in the hero. Its
  two gradient stops are `--color-brand-from` / `--color-brand-to` tokens; the
  icon is the only element on the site permitted a gradient.
- **`public/`** — `favicon.svg`, `icon-512.png` (also the Open Graph image) and
  a full-bleed 180px `apple-touch-icon.png`.

If the app icon ever changes, regenerate the rasters and update `<AppIcon>` and
`public/favicon.svg` to match:

```bash
swift ../tools/makeicon.swift /tmp/icon-1024.png
sips -Z 512 /tmp/icon-1024.png --out public/icon-512.png
sips -c 840 840 /tmp/icon-1024.png --out /tmp/icon-bleed.png
sips -Z 180 /tmp/icon-bleed.png --out public/apple-touch-icon.png
```

## Deploy to Cloudflare Workers

Config lives in `wrangler.jsonc` (worker name `dropline-website`); the
Cloudflare Vite plugin in `vite.config.ts` builds the Worker bundle.

```bash
pnpm dlx wrangler login    # once
pnpm deploy                # runs `pnpm build && wrangler deploy`
```

No bindings, secrets or environment variables are required — the page is
static apart from SSR. To serve it from a custom domain, add a `routes` entry
to `wrangler.jsonc`, then update `SITE_URL` in `src/lib/head.ts` to match.
