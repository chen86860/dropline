import { FlowDiagram } from './FlowDiagram'
import { HeroBackdrop } from './HeroBackdrop'
import { HeroDemo } from './HeroDemo'
import { TemplateResolver } from './TemplateResolver'
import { AppleIcon, ArrowIcon, BookIcon, DocIcon } from './icons'
import { Reveal } from './Reveal'
import { SiteFooter } from './SiteFooter'
import { SHELL, SiteHeader } from './SiteHeader'
import { CONTENT, DOWNLOAD_DMG, type Lang } from '../content'
import { docHref } from '../docs/routes'
import { AppLink } from '../lib/links'

/** Split Studio: text half and proof half, and the pairing flips down the page. */
const SPLIT = 'grid grid-cols-[minmax(0,1fr)] gap-10 xl:gap-24 xl:items-center'
const SPLIT_LEFT = `${SPLIT} xl:grid-cols-[minmax(0,7fr)_minmax(0,5fr)]`
const SPLIT_RIGHT = `${SPLIT} xl:grid-cols-[minmax(0,5fr)_minmax(0,7fr)]`

/* Bottom padding a step deeper than the top — optically, that reads as even */
const SECTION = 'border-t border-rule pt-20 pb-24'
/* Every band below the hero shares one floor height, content centred in it,
   so the page scrolls in an even rhythm. */
const BAND = 'min-h-160'
const BAND_STACK = `${BAND} flex flex-col justify-center`

/* Each preset's own mark, from Simple Icons / Iconify brand sets or the
   project's site. SM.MS and EasyImage publish no usable icon, so they keep
   the letter. */
const HOST_ICONS: Record<string, string> = {
  'hosts/s3': '/hosts/s3.svg',
  'hosts/r2': '/hosts/r2.svg',
  'hosts/oss': '/hosts/oss.svg',
  'hosts/cos': '/hosts/cos.svg',
  'hosts/minio': '/hosts/minio.svg',
  'hosts/imgur': '/hosts/imgur.svg',
  'hosts/lsky-chevereto': '/hosts/lsky.png',
}
const HEAD_TITLE = 'text-3xl font-semibold'
const LEDE = 'max-w-[60ch] text-md text-muted'

/* The quieter ask beside a primary button — a link, not a second button */
const TEXT_LINK =
  'inline-flex min-h-10 items-center gap-2 text-base font-medium text-ink-2 transition-colors duration-micro ease-out hover:text-accent'

export function Landing({ lang }: { lang: Lang }) {
  const t = CONTENT[lang]

  return (
    <>
      <SiteHeader lang={lang} />

      <main id="main">
        {/* ── Hero — H2 diptych: statement left, the upload playing out right */}
        <section className="relative isolate -mt-(--banner-height) flex min-h-dvh flex-col justify-center pt-(--banner-height)">
          <HeroBackdrop />
          <div className={`${SHELL} ${SPLIT_LEFT} pt-16 pb-24`}>
          <div>
            <p className="inline-flex items-center gap-3 rounded-sm border border-rule bg-paper-2 px-3 py-1 font-mono text-2xs tracking-mono text-muted">
              <AppleIcon className="size-3.5 text-ink" />
              {t.hero.badge.map((part) => (
                <span key={part}>{part}</span>
              ))}
            </p>

            {/* Balanced wrapping keeps the headline from stranding a single
                glyph on its own line — CJK breaks anywhere, so it needs help. */}
            <h1 className="hero-title mt-6 text-balance text-display font-semibold">{t.hero.title}</h1>
            <p className="mt-6 max-w-[46ch] text-md text-muted">{t.hero.lede}</p>

            {/* One button; the docs are a link beside it */}
            <div className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-3">
              <a className="btn btn-primary" href={DOWNLOAD_DMG} rel="noopener">
                <AppleIcon />
                {t.hero.primary}
              </a>
              <AppLink className={TEXT_LINK} href={docHref(lang, '')}>
                <BookIcon />
                {t.docsBand.cta}
              </AppLink>
            </div>

            <ul className="mt-8 flex flex-wrap gap-x-4 gap-y-2">
              {t.hero.meta.map((item) => (
                <li key={item} className="mono-label">
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <HeroDemo labels={t.hero.demo} />
          </div>
        </section>

        {/* ── Hosts — two rows drifting in opposite directions, the presets
              above and what the custom engines speak below. Every preset is
              a link into its configuration page. ───────────────────────── */}
        <section id={t.hosts.id} className={`dots-bg relative isolate border-y border-rule bg-paper-2 pt-20 pb-24 ${BAND_STACK}`}>
          <Reveal className={SHELL}>
            <h2 className={`${HEAD_TITLE} max-w-[18ch]`}>{t.hosts.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.hosts.lede}</p>
          </Reveal>

          <div className="mt-12 grid gap-3" aria-label={t.hosts.presetsLabel}>
            <div className="marquee">
              {[0, 1].map((track) => (
                <ul
                  key={track}
                  className="marquee__track"
                  /* The duplicate exists only to make the loop seamless; a
                     screen reader should meet this list once. */
                  aria-hidden={track === 1 ? 'true' : undefined}
                >
                  {t.hosts.presets.map((preset) => (
                    <li key={preset.slug}>
                      <AppLink
                        className="host-tile"
                        href={docHref(lang, preset.slug)}
                        tabIndex={track === 1 ? -1 : undefined}
                      >
                        <span className="host-tile__mark">
                          {HOST_ICONS[preset.slug] ? (
                            <img src={HOST_ICONS[preset.slug]} alt="" className="size-5 object-contain" />
                          ) : (
                            preset.label.slice(0, 1)
                          )}
                        </span>
                        {preset.label}
                      </AppLink>
                    </li>
                  ))}
                </ul>
              ))}
            </div>

            <div className="marquee" aria-hidden="true">
              {[0, 1].map((track) => (
                <ul key={track} className="marquee__track marquee__track--reverse">
                  {t.hosts.engines.map((engine) => (
                    <li key={engine}>
                      <span className="chip">{engine}</span>
                    </li>
                  ))}
                </ul>
              ))}
            </div>
          </div>

          <div className={`${SHELL} mt-10`}>
            <AppLink
              className="inline-flex items-center gap-2 text-sm font-medium text-accent transition-colors duration-micro ease-out hover:text-accent-deep"
              href={docHref(lang, 'hosts/overview')}
            >
              {t.hosts.presetsCta}
            </AppLink>
          </div>
        </section>

        {/* ── Five ways in — the diagram on the wide side, the diptych flips ── */}
        <section id={t.ways.id} className={`${SHELL} ${SECTION} ${SPLIT_LEFT} ${BAND} content-center`}>
          {/* Text first in the DOM so stacked mobile reads head → proof;
              the diptych only flips where there are two columns to flip. */}
          <Reveal className="xl:order-2">
            <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.ways.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.ways.lede}</p>

            <ul className="mt-8 border-t border-rule">
              {t.ways.items.map((item) => (
                <li
                  key={item.key}
                  className="grid grid-cols-[6rem_minmax(0,1fr)] items-baseline gap-4 border-b border-rule py-3"
                >
                  <span className="font-mono text-2xs tracking-mono text-accent uppercase">
                    {item.key}
                  </span>
                  <span className="text-base text-ink-2">{item.desc}</span>
                </li>
              ))}
            </ul>
          </Reveal>

          <Reveal step={1} className="xl:order-1">
            <FlowDiagram inputs={t.ways.items.map((item) => item.key)} output={t.ways.output} />
          </Reveal>
        </section>

        {/* ── The page's one dark beat ──────────────────────────────────── */}
        <section
          id={t.own.id}
          className={`grain relative isolate overflow-hidden bg-graphite pt-20 pb-24 text-graphite-muted ${BAND_STACK}`}
        >
          <div className={`${SHELL} ${SPLIT_LEFT}`}>
            <Reveal>
              <h2 className={`${HEAD_TITLE} max-w-[18ch] text-graphite-ink`}>{t.own.title}</h2>
              <p className="mt-4 max-w-[60ch] text-md text-graphite-muted">{t.own.lede}</p>

              {/* Two ends and nothing between them */}
              <div className="mt-10 flex items-center gap-3 font-mono text-xs" aria-hidden="true">
                <span className="rounded-md border border-graphite-rule px-3 py-2 text-graphite-ink">
                  {t.own.route[0]}
                </span>
                <span className="route-line" />
                <span className="rounded-md border border-accent-soft px-3 py-2 text-accent-soft">
                  {t.own.route[1]}
                </span>
              </div>
            </Reveal>

            <Reveal step={1}>
              <TemplateResolver
                keyLabel={t.own.templateKeyLabel}
                keyTemplate={t.own.templateKey}
                urlLabel={t.own.templateUrlLabel}
                urlTemplate={t.own.templateUrl}
                varsLabel={t.own.varsLabel}
                vars={t.own.vars}
              />
            </Reveal>
          </div>
        </section>

        {/* ── Docs — the handover from page to manual ───────────────────── */}
        <section id={t.docsBand.id} className={`${SHELL} ${SECTION} ${BAND_STACK}`}>
          <Reveal>
            <p className="mono-label">{t.docsBand.eyebrow}</p>
            <h2 className={`${HEAD_TITLE} mt-3 max-w-[16ch]`}>{t.docsBand.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.docsBand.lede}</p>
          </Reveal>

          <ul className="mt-10 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {t.docsBand.cards.map((card, index) => (
              <Reveal as="li" key={card.slug} step={index}>
                <AppLink
                  href={docHref(lang, card.slug)}
                  className="group flex h-full flex-col gap-2 rounded-lg border border-rule bg-paper-2 p-6 transition duration-micro ease-out hover:-translate-y-0.5 hover:border-accent hover:bg-paper hover:shadow-lift"
                >
                  <span className="mb-4 grid size-10 place-items-center rounded-lg bg-accent-wash text-accent">
                    <DocIcon slug={card.slug} className="size-5" />
                  </span>
                  <span className="flex items-center gap-2 text-md font-medium text-ink transition-colors duration-micro ease-out group-hover:text-accent">
                    {card.title}
                    <ArrowIcon className="-translate-x-1 opacity-0 transition duration-short ease-out group-hover:translate-x-0 group-hover:opacity-100" />
                  </span>
                  <span className="text-sm text-muted">{card.body}</span>
                </AppLink>
              </Reveal>
            ))}
          </ul>
        </section>

        {/* ── FAQ — every answer on the page, two columns, nothing to open:
              readers scan it and crawlers read it ─────────────────────── */}
        <section id={t.faq.id} className={`${SHELL} ${SECTION} ${BAND_STACK}`}>
          <Reveal>
            <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.faq.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.faq.lede}</p>
          </Reveal>

          <dl className="mt-8 grid gap-x-16 gap-y-8 border-t border-rule pt-8 lg:grid-cols-2">
            {t.faq.items.map((item) => (
              <div key={item.q}>
                <dt className="text-md font-medium tracking-tight text-ink">{item.q}</dt>
                <dd className="mt-2 max-w-[65ch] text-base text-muted">{item.a}</dd>
              </div>
            ))}
          </dl>
        </section>

        {/* ── Install — one button, no second ask ───────────────────────── */}
        {/* The page ends on the same ground it started on */}
        <section id={t.install.id} className={`relative isolate border-t border-rule pt-20 pb-24 ${BAND_STACK}`}>
          <HeroBackdrop />
          <div className={`${SHELL} ${SPLIT_RIGHT}`}>
          <Reveal className="xl:order-2">
            <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.install.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.install.lede}</p>

            <div className="mt-10 grid justify-items-start gap-3">
              <a className="btn btn-primary" href={DOWNLOAD_DMG} rel="noopener">
                <AppleIcon />
                {t.install.cta}
                <ArrowIcon />
              </a>
              <p className="mono-label flex flex-wrap gap-x-4 gap-y-1">
                {t.install.ctaMeta.map((part) => (
                  <span key={part}>{part}</span>
                ))}
              </p>

              {/* Homebrew — the second path, deliberately quieter than the button */}
              <div className="mt-6 grid w-full justify-items-start gap-2">
                <p className="mono-label">{t.install.brew.label}</p>
                <code className="break-anywhere block w-full rounded-md border border-rule bg-paper-2 px-4 py-3 font-mono text-xs text-ink">
                  <span className="text-neutral select-none">$ </span>
                  {t.install.brew.command}
                  <span className="caret" aria-hidden="true" />
                </code>
              </div>
            </div>
          </Reveal>

          <ol className="grid gap-6 xl:order-1">
            {t.install.steps.map((step, index) => (
              <Reveal
                as="li"
                key={step.title}
                step={index}
                className="grid grid-cols-[2rem_minmax(0,1fr)] gap-4"
              >
                <span className="pt-1 font-mono text-2xs tracking-mono text-accent">
                  {String(index + 1).padStart(2, '0')}
                </span>
                <div>
                  <h3 className="text-md font-medium tracking-tight">{step.title}</h3>
                  <p className="mt-1 max-w-[60ch] text-muted">{step.body}</p>
                  {step.code ? (
                    <code className="break-anywhere mt-3 block rounded-md border border-rule bg-paper-2 px-4 py-3 font-mono text-xs text-ink">
                      {step.code}
                    </code>
                  ) : null}
                </div>
              </Reveal>
            ))}
          </ol>
          </div>
        </section>
      </main>

      <SiteFooter lang={lang} />
    </>
  )
}

