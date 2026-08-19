import { AppleIcon, ArrowIcon, BookIcon } from './icons'
import { Reveal } from './Reveal'
import { SiteFooter } from './SiteFooter'
import { SHELL, SiteHeader } from './SiteHeader'
import { CONTENT, DOWNLOAD_DMG, REPO, type Lang } from '../content'
import { docHref } from '../docs/routes'
import { AppLink } from '../lib/links'
import { useUploadDemo } from '../lib/motion'

/** Split Studio: text half and proof half, and the pairing flips down the page. */
const SPLIT = 'grid grid-cols-[minmax(0,1fr)] gap-10 xl:gap-24 xl:items-center'
const SPLIT_LEFT = `${SPLIT} xl:grid-cols-[minmax(0,7fr)_minmax(0,5fr)]`
const SPLIT_RIGHT = `${SPLIT} xl:grid-cols-[minmax(0,5fr)_minmax(0,7fr)]`

const SECTION = 'border-t border-rule py-24'
const HEAD_TITLE = 'text-3xl font-semibold'
const LEDE = 'max-w-[60ch] text-md text-muted'

/* Same 5/7 diptych, but deliberately without `items-center`: the head column
   must stretch or its sticky wrapper has no distance to travel. */
const SPLIT_FAQ =
  'grid grid-cols-[minmax(0,1fr)] gap-10 xl:grid-cols-[minmax(0,5fr)_minmax(0,7fr)] xl:gap-24'

export function Landing({ lang }: { lang: Lang }) {
  const t = CONTENT[lang]

  return (
    <>
      <SiteHeader lang={lang} />

      <main>
        {/* ── Hero — H2 diptych: statement left, machine readout right ─── */}
        <section className={`${SHELL} ${SPLIT_LEFT} pt-24 pb-16`}>
          <div>
            <p className="inline-flex items-center gap-2 rounded-sm border border-rule bg-paper-2 px-3 py-1.5 font-mono text-2xs tracking-mono text-muted">
              <AppleIcon className="size-3.5 text-ink" />
              {t.hero.badge}
            </p>

            <h1 className="mt-5 text-display font-semibold">{t.hero.title}</h1>
            <p className="mt-6 max-w-[46ch] text-md text-muted">{t.hero.lede}</p>

            <div className="mt-10 flex flex-wrap gap-3">
              <a className="btn btn-primary" href={DOWNLOAD_DMG} rel="noopener">
                <AppleIcon />
                {t.hero.primary}
              </a>
              <AppLink className="btn btn-secondary" href={docHref(lang, '')}>
                <BookIcon />
                {t.docsBand.cta}
              </AppLink>
              <a
                className="inline-flex min-h-11 items-center px-2 text-base text-muted transition-colors duration-micro ease-out hover:text-accent"
                href={REPO}
                rel="noopener"
              >
                {t.hero.secondary}
              </a>
            </div>

            <p className="mt-4 max-w-[46ch] text-sm text-muted">{t.hero.requirements}</p>

            <ul className="mt-6 flex flex-wrap gap-x-4 gap-y-2">
              {t.hero.meta.map((item) => (
                <li key={item} className="mono-label">
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <Readout copy={t.hero.readout} />
        </section>

        {/* ── The hosts, moving past ─────────────────────────────────────
            A quiet strip rather than a section: it answers "does it work with
            mine?" before the reader has to go looking, and every name is a
            real link into that host's configuration page. */}
        <section className="border-y border-rule bg-paper-2 py-5" aria-label={t.hosts.presetsLabel}>
          <div className="marquee">
            {[0, 1].map((track) => (
              <ul
                key={track}
                className="marquee__track"
                /* The duplicate exists only to make the loop seamless; a screen
                   reader should meet this list once. */
                aria-hidden={track === 1 ? 'true' : undefined}
              >
                {t.hosts.presets.map((preset) => (
                  <li key={preset.slug}>
                    <AppLink className="chip" href={docHref(lang, preset.slug)}>
                      {preset.label}
                    </AppLink>
                  </li>
                ))}
                {t.hosts.engines.map(([engine]) => (
                  <li key={engine}>
                    <span className="chip text-muted">{engine}</span>
                  </li>
                ))}
              </ul>
            ))}
          </div>
        </section>

        {/* ── Five ways in — the diptych flips ──────────────────────────── */}
        <section id={t.ways.id} className={`${SHELL} ${SECTION} ${SPLIT_RIGHT}`}>
          {/* Heading first in the DOM so stacked mobile reads head → proof;
              the diptych only flips where there are two columns to flip. */}
          <Reveal className="xl:order-2">
            <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.ways.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.ways.lede}</p>
            <p className={`${LEDE} mt-6`}>{t.ways.note}</p>
          </Reveal>

          <ul className="border-t border-rule xl:order-1">
            {t.ways.items.map((item, index) => (
              <Reveal
                as="li"
                key={item.key}
                delay={index * 70}
                className="group grid grid-cols-[minmax(0,1fr)] gap-1 border-b border-rule py-4 sm:grid-cols-[7rem_minmax(0,1fr)] sm:items-baseline sm:gap-4"
              >
                <span className="font-mono text-2xs tracking-mono text-accent uppercase">
                  {item.key}
                </span>
                <span className="text-base text-ink-2">{item.desc}</span>
              </Reveal>
            ))}
          </ul>
        </section>

        {/* ── The page's one dark beat ──────────────────────────────────── */}
        <section id={t.own.id} className="bg-graphite py-24 text-graphite-muted">
          <div className={`${SHELL} ${SPLIT_LEFT}`}>
            <Reveal>
              <h2 className={`${HEAD_TITLE} max-w-[18ch] text-graphite-ink`}>{t.own.title}</h2>
              <p className="mt-4 max-w-[60ch] text-md text-graphite-muted">{t.own.lede}</p>

              <div className="mt-10 grid gap-6">
                {t.own.points.map((point) => (
                  <div key={point.title}>
                    <h3 className="text-md font-medium tracking-tight text-graphite-ink">
                      {point.title}
                    </h3>
                    <p className="mt-1 max-w-[60ch] text-base">{point.body}</p>
                  </div>
                ))}
              </div>
            </Reveal>

            <Reveal
              delay={120}
              className="grid gap-4 rounded-md border border-graphite-rule bg-graphite-2 p-6 font-mono text-xs"
            >
              <div className="grid gap-1">
                <span className="mono-label text-graphite-muted">{t.own.templateKeyLabel}</span>
                <span className="break-anywhere text-graphite-ink">{t.own.templateKey}</span>
              </div>
              <div className="grid gap-1">
                <span className="mono-label text-graphite-muted">{t.own.templateUrlLabel}</span>
                <span className="break-anywhere text-graphite-ink">{t.own.templateUrl}</span>
              </div>
              <div className="grid gap-2 border-t border-graphite-rule pt-4">
                <span className="mono-label text-graphite-muted">{t.own.varsLabel}</span>
                <ul className="flex flex-wrap gap-1">
                  {t.own.vars.map((name) => (
                    <li
                      key={name}
                      className="rounded-[4px] border border-graphite-rule px-2 py-0.5 text-2xs whitespace-nowrap text-graphite-muted"
                    >
                      {name}
                    </li>
                  ))}
                </ul>
              </div>
            </Reveal>
          </div>
        </section>

        {/* ── Hosts and engines — F3 spec sheet ─────────────────────────── */}
        <section id={t.hosts.id} className={`${SHELL} ${SECTION} ${SPLIT_LEFT}`}>
          <Reveal>
            <h2 className={`${HEAD_TITLE} max-w-[18ch]`}>{t.hosts.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.hosts.lede}</p>

            <p className="mono-label mt-10">{t.hosts.presetsLabel}</p>
            <ul className="mt-4 flex flex-wrap gap-1.5">
              {t.hosts.presets.map((preset) => (
                <li key={preset.slug}>
                  <AppLink className="chip" href={docHref(lang, preset.slug)}>
                    {preset.label}
                  </AppLink>
                </li>
              ))}
            </ul>

            <AppLink
              className="mt-5 inline-flex items-center gap-2 text-sm text-accent transition-colors duration-micro ease-out hover:text-accent-deep"
              href={docHref(lang, 'hosts/overview')}
            >
              {t.hosts.presetsCta}
            </AppLink>
          </Reveal>

          <Reveal delay={120}>
            <table className="tnum w-full border-collapse text-left">
              <caption className="mono-label pb-3 text-left">{t.hosts.enginesCaption}</caption>
              <thead className="sr-only">
                <tr>
                  <th scope="col">{t.hosts.engineHead[0]}</th>
                  <th scope="col">{t.hosts.engineHead[1]}</th>
                </tr>
              </thead>
              <tbody className="max-md:block">
                {[
                  ...t.hosts.engines,
                  [t.hosts.authLabel, t.hosts.auth] as [string, string],
                ].map(([engine, use]) => (
                  <tr key={engine} className="border-b border-rule max-md:block max-md:py-4">
                    <th
                      scope="row"
                      className="break-anywhere py-4 pr-4 align-baseline font-mono text-xs font-medium text-ink max-md:block max-md:py-0"
                    >
                      {engine}
                    </th>
                    <td className="py-4 align-baseline text-base text-muted max-md:mt-1 max-md:block max-md:py-0">
                      {use}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className={`${LEDE} mt-6`}>{t.hosts.custom}</p>
          </Reveal>
        </section>

        {/* ── Docs — the handover from page to manual ───────────────────── */}
        <section id={t.docsBand.id} className={`${SHELL} ${SECTION}`}>
          <Reveal>
            <p className="mono-label">{t.docsBand.eyebrow}</p>
            <h2 className={`${HEAD_TITLE} mt-3 max-w-[16ch]`}>{t.docsBand.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.docsBand.lede}</p>
          </Reveal>

          <ul className="mt-10 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            {t.docsBand.cards.map((card, index) => (
              <Reveal as="li" key={card.slug} delay={index * 70}>
                <AppLink
                  href={docHref(lang, card.slug)}
                  className="group flex h-full flex-col gap-2 rounded-md border border-rule bg-paper-2 p-5 transition-colors duration-short ease-out hover:border-accent hover:bg-paper"
                >
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

        {/* ── FAQ — real <details>, so answers are in the DOM for crawlers
              whether or not the visitor opens them ─────────────────────── */}
        <section id={t.faq.id} className={`${SHELL} ${SECTION} ${SPLIT_FAQ}`}>
          {/* Pinned beside a tall list so the reader keeps their place. The
              grid item has to stretch for sticky to have any travel, hence the
              wrapper. It docks below the nav and carries no z-index, so the
              nav's own layer stays on top while scrolling. */}
          <div>
            <div className="xl:sticky xl:top-[calc(var(--banner-height)+2.5rem)]">
              <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.faq.title}</h2>
              <p className={`${LEDE} mt-4`}>{t.faq.lede}</p>
            </div>
          </div>

          <div className="border-t border-rule">
            {t.faq.items.map((item) => (
              <details key={item.q} className="faq border-b border-rule">
                <summary className="flex min-h-14 cursor-pointer list-none items-center gap-4 py-4 text-md font-medium text-ink transition-colors duration-micro ease-out hover:text-accent">
                  <span className="flex-1">{item.q}</span>
                  <span className="faq__mark" aria-hidden="true" />
                </summary>
                <p className="max-w-[68ch] pb-5 text-base text-muted">{item.a}</p>
              </details>
            ))}
          </div>
        </section>

        {/* ── Install — one button, no second ask ───────────────────────── */}
        <section
          id={t.install.id}
          className={`${SHELL} ${SPLIT_RIGHT} border-t border-rule pt-36 pb-24`}
        >
          <Reveal className="xl:order-2">
            <h2 className={`${HEAD_TITLE} max-w-[16ch]`}>{t.install.title}</h2>
            <p className={`${LEDE} mt-4`}>{t.install.lede}</p>

            <div className="mt-10 grid justify-items-start gap-3">
              <a className="btn btn-primary" href={DOWNLOAD_DMG} rel="noopener">
                <AppleIcon />
                {t.install.cta}
                <ArrowIcon />
              </a>
              <p className="mono-label">{t.install.ctaMeta}</p>

              {/* Homebrew — the second path, deliberately quieter than the button */}
              <div className="mt-6 grid w-full justify-items-start gap-2">
                <p className="mono-label">{t.install.brew.label}</p>
                <code className="break-anywhere block w-full rounded-sm border border-rule bg-paper-2 px-4 py-3 font-mono text-xs text-ink">
                  {t.install.brew.command}
                </code>
                <p className="max-w-[60ch] text-sm text-muted">{t.install.brew.note}</p>
              </div>

              <p className="mt-3 max-w-[60ch] text-sm text-muted">{t.install.note}</p>
              <p className="max-w-[60ch] text-sm text-muted">{t.install.source}</p>
            </div>
          </Reveal>

          <ol className="grid gap-6 xl:order-1">
            {t.install.steps.map((step, index) => (
              <Reveal
                as="li"
                key={step.title}
                delay={index * 90}
                className="grid grid-cols-[1.75rem_minmax(0,1fr)] gap-4"
              >
                <span className="pt-[0.35em] font-mono text-2xs tracking-mono text-accent">
                  {String(index + 1).padStart(2, '0')}
                </span>
                <div>
                  <h3 className="text-md font-medium tracking-tight">{step.title}</h3>
                  <p className="mt-1 max-w-[60ch] text-muted">{step.body}</p>
                  {step.code ? (
                    <code className="break-anywhere mt-3 block rounded-sm border border-rule bg-paper-2 px-4 py-3 font-mono text-xs text-ink">
                      {step.code}
                    </code>
                  ) : null}
                </div>
              </Reveal>
            ))}
          </ol>
        </section>
      </main>

      <SiteFooter lang={lang} />
    </>
  )
}

/**
 * The hero artefact: a machine readout of one upload, drawn with type and
 * hairlines. Deliberately not a mock app window — no fake chrome, no dots.
 *
 * It animates through the four states of a real upload and then holds. The
 * server renders the last of those states, so the markup is complete and
 * legible before — and without — any of this.
 */
function Readout({ copy }: { copy: (typeof CONTENT)['en']['hero']['readout'] }) {
  const { phase, progress, typed } = useUploadDemo(copy.url)

  return (
    <figure className="m-0 overflow-hidden rounded-md border border-graphite-rule bg-graphite font-mono text-xs/relaxed text-graphite-muted shadow-whisper">
      <div className="flex items-baseline gap-3 px-4 py-3">
        <span className="break-anywhere text-graphite-ink">{copy.file}</span>
        <span className="ml-auto whitespace-nowrap">{copy.size}</span>
      </div>

      {/* The transfer bar sits on the hairline between the two rows, so it
          reads as the rule filling rather than as a widget bolted on. */}
      <div className="transfer" aria-hidden="true">
        <span className="transfer__fill" style={{ width: `${Math.round(progress * 100)}%` }} />
      </div>

      <div className="flex items-baseline gap-3 px-4 py-3">
        <span className="tracking-mono whitespace-nowrap text-accent-soft">{copy.verb}</span>
        <span className="break-anywhere">{copy.key}</span>
        <span
          className={[
            'ml-auto rounded-[4px] border border-accent-soft px-2 text-2xs tracking-mono whitespace-nowrap text-accent-soft',
            'transition-opacity duration-short ease-out',
            phase >= 2 ? 'opacity-100' : 'opacity-0',
          ].join(' ')}
        >
          {copy.status}
        </span>
      </div>

      <figcaption className="grid gap-1 border-t border-graphite-rule bg-graphite-2 p-4">
        <span className="mono-label text-graphite-muted">{copy.caption}</span>
        <span className="break-anywhere min-h-[1.65em] text-graphite-ink">
          {typed}
          <span
            className={[
              'inline-block w-[0.55em] border-b-2 border-accent-soft align-baseline',
              typed === copy.url ? 'opacity-0' : '',
            ].join(' ')}
            aria-hidden="true"
          />
        </span>
      </figcaption>
    </figure>
  )
}
