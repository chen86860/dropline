# Dropline — website

The landing page and manual for [Dropline](../README.md). TanStack Start +
React 19 + Tailwind v4, server-rendered on Cloudflare Workers.

```bash
pnpm install
pnpm dev        # http://localhost:3000
pnpm build      # dist/client + dist/server
pnpm typecheck
```

## Bilingual routing

| Route | Language |
| --- | --- |
| `/` | English landing page (also the `x-default` for search engines) |
| `/zh` | 简体中文首页 |
| `/docs`, `/docs/*` | English manual |
| `/zh/docs`, `/zh/docs/*` | 简体中文手册 |

Both landing routes render the same `<Landing>` component; every string lives in
[`src/content.ts`](src/content.ts), so a copy change touches one file.

Language is resolved in three steps:

1. **Auto** — a small script in `<head>` ([`src/routes/__root.tsx`](src/routes/__root.tsx))
   runs on the English tree only (`/` and `/docs/…`). If `navigator.language`
   starts with `zh` and the visitor has never chosen, it replaces the URL with
   the `/zh` equivalent before first paint, so there is no flash of the wrong
   language — and a Chinese reader landing on `/docs/hosts/r2` from a search
   result gets `/zh/docs/hosts/r2` rather than a page they cannot read.
2. **Manual** — the `EN / 中文` toggle in the nav (and the language link in the
   footer) navigates between the two routes.
3. **Remembered** — a manual choice writes a `dl-lang` cookie for a year, after
   which step 1 never fires again.

Because each language is a real, server-rendered URL, both are crawlable and
shareable. `hreflang` and canonical tags are emitted from
[`src/lib/head.ts`](src/lib/head.ts) — **set `SITE_URL` there to the real
domain before going live**, since it drives the canonical and Open Graph tags.

## The docs

The manual is Markdown. Everything else about it is derived.

```
src/docs/
  content/en/**.md     the English manual — one file per page
  content/zh/**.md     the same tree, translated
  nav.ts               sidebar order + the chrome's own strings
  registry.ts          Markdown modules → the `Doc` shape, sidebar, pager
  en.ts / zh.ts        one eager glob per language
  routes.ts            just the URLs — safe for the landing page to import
```

**Markdown is compiled at build time**, by
[`plugins/markdown.ts`](plugins/markdown.ts), into a module exporting finished
HTML, a table of contents and the plain text. No parser and no highlighter
reach the Worker or the browser: a docs page is server-rendered from a string,
so the complete text of every page is in the first response — the same SEO
property the landing page has, for twenty-odd more pages.

Adding a page is two steps:

1. Write `src/docs/content/<lang>/<group>/<slug>.md` with `title` and
   `description` frontmatter. The `<h1>` and the sidebar entry both come from
   `title`; the `<meta name="description">` and the search excerpt come from
   `description`.
2. Add its slug to the right group in [`src/docs/nav.ts`](src/docs/nav.ts).

That is all — the route (`/docs/$`), the head tags, the sidebar, the prev/next
pager, the search index and `sitemap.xml` all pick it up. A slug listed in
`nav.ts` with no matching file is skipped rather than rendered as a dead link,
so a half-finished translation degrades quietly instead of breaking.

**Search** is a plain scan over the compiled pages, scored by where the term
hits (title > headings > description > body). At this size an index would be
more machinery than the thing it indexes. `⌘K`, `ctrl-K` or `/` opens it.

**Code blocks** are highlighted by Shiki at build time. The theme's background
is stripped so blocks sit on the site's own graphite token, but its foreground
is kept — an unhighlighted block (` ```text `, or any language Shiki does not
know) carries no per-token spans and would otherwise inherit the page's dark
body colour onto a dark card.

**Bundle split.** Each language's docs are their own eager glob and so their own
chunk; the landing page imports only `routes.ts` and ships none of it.

## Motion

The landing page reveals sections as they approach the viewport, and the hero
readout animates one upload end to end. Two rules hold throughout
([`src/lib/motion.ts`](src/lib/motion.ts)):

- **The server-rendered state is the finished state.** The readout's markup
  shows a completed upload with the full URL; the animation only takes it away
  and replays it. Nothing animated is load-bearing for content.
- **Anything that does not scroll gets the whole page.** The reveal's hidden
  state is on a 2.5-second timer that the first real scroll disarms. A reader
  scrolls and gets the animation; a crawler, link preview or screenshot tool
  never scrolls, so the timer fires and every section is shown at once. Without
  this a full-page capture is a page of empty boxes — see the `data-reveal-all`
  rule in `app.css`.

Both are additionally skipped under `prefers-reduced-motion`, and the hidden
state is behind `@media (scripting: enabled)` so JavaScript-off visitors just
see the page.

## Design system

`src/styles/tokens.css` is a Tailwind v4 `@theme` block holding the whole
system — colours (OKLCH), the three font families, the type scale, easings and
motion buckets. Markup references tokens by name (`bg-paper`, `text-ink`,
`duration-micro`); no component hard-codes a colour or a font. The file is
portable: drop it into another Tailwind v4 project and the system comes with
it. `src/styles/app.css` holds only base rules and the handful of component
classes Tailwind has no utility for.

## SEO

Every route is server-rendered, so the full text — including every FAQ answer
and every word of the manual — is in the initial HTML. `<details>` keeps answers collapsed visually while
leaving them in the DOM, which is what crawlers read.

Emitted per landing route from [`src/lib/head.ts`](src/lib/head.ts): title,
description, canonical, the `hreflang` triple (`en` / `zh-Hans` / `x-default`),
Open Graph, and a JSON-LD `@graph` with two nodes.

- **`SoftwareApplication`** — the one that earns rich treatment here. Declares
  a free macOS 13+ app with its download URL, licence and author.
- **`FAQPage`** — kept because assistants and AI search read it, but be aware
  Google narrowed FAQ rich results to government and health sites in 2023, so
  **this will not produce FAQ snippets in Google Search.** The real benefit is
  indexable long-tail content answering questions people search for.

Every question and answer in the JSON-LD is byte-identical to what the page
renders; that parity is a requirement for the markup to be valid at all. If you
edit `faq` in `src/content.ts`, both update together — there is no second copy.

Docs pages get their own head from
[`src/lib/docs-head.ts`](src/lib/docs-head.ts): the same canonical and Open
Graph treatment, plus a `TechArticle` / `Collection` / `BreadcrumbList` graph.
Its `hreflang` alternates are emitted **only when the translation actually
exists** — pointing `hreflang` at a missing page is worse than omitting it. The
docs 404 is `noindex`.

`sitemap.xml` is **generated at build time** by
[`plugins/sitemap.ts`](plugins/sitemap.ts) from the route list and the Markdown
tree, with the `hreflang` pairs worked out per page — a hand-maintained sitemap
across ~50 URLs would advertise 404s within a release or two. It is emitted
into the client build and served from the root; the dev server returns the same
bytes. `public/robots.txt` and the `SITE_URL` constants in `plugins/sitemap.ts`
and `src/lib/head.ts` hard-code the domain, so change those three together when
the real domain is settled.

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
