import {
  ArrowRight,
  BookOpen,
  BracketsCurly,
  CaretRight,
  HardDrives,
  Lightning,
  Wrench,
  FilePdf,
  FilmStrip,
  ImageSquare,
  UploadSimple,
  List,
  MagnifyingGlass,
  X,
} from '@phosphor-icons/react/ssr'

/** One icon set (Phosphor), one weight, one size — never mixed. The Apple mark
    is the exception: it is a logo, drawn from Apple's own outline. */

type IconProps = { className?: string }

const ICON = 'shrink-0'

/** 16px unless the caller sizes it — two `size-*` classes would fight. */
function sized(className: string) {
  return /(^|\s)size-/.test(className) ? className : `size-4 ${className}`
}

export function ArrowIcon({ className = '' }: IconProps) {
  return <ArrowRight className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

/**
 * The Dropline app icon, drawn rather than loaded so it stays crisp at 20px in
 * the nav and 64px in the hero. The geometry is the same one
 * `tools/makeicon.swift` renders into the .icns — rounded square inset 9%,
 * corner radius 22%, Lucide arrow-up-from-line at 44% height, 2-unit round
 * stroke. If the app icon changes, change this and public/favicon.svg with it.
 */
export function AppIcon({
  className = '',
  title,
}: IconProps & { title?: string }) {
  return (
    <svg
      className={`shrink-0 ${className}`}
      viewBox="0 0 1024 1024"
      role={title ? 'img' : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
    >
      <defs>
        <linearGradient id="dropline-icon" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="var(--color-brand-from)" />
          <stop offset="1" stopColor="var(--color-brand-to)" />
        </linearGradient>
      </defs>
      <rect
        x="92.16"
        y="92.16"
        width="839.68"
        height="839.68"
        rx="225.28"
        fill="url(#dropline-icon)"
      />
      <g
        fill="none"
        stroke="var(--color-brand-glyph)"
        strokeWidth="45.056"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M512 309.248V624.64" />
        <path d="M376.832 444.416 512 309.248l135.168 135.168" />
        <path d="M354.304 714.752h315.392" />
      </g>
    </svg>
  )
}

export function SearchIcon({ className = '' }: IconProps) {
  return <MagnifyingGlass className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

export function ChevronIcon({ className = '' }: IconProps) {
  return <CaretRight className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

/**
 * The menu toggle: the list and the cross are stacked and trade places, so
 * opening the menu reads as one glyph turning into the other rather than a swap.
 */
export function MenuToggleIcon({ open, className = '' }: IconProps & { open: boolean }) {
  const glyph = `${ICON} size-4 col-start-1 row-start-1 transition duration-short ease-out`
  return (
    <span className={`inline-grid ${className}`} aria-hidden="true">
      <List className={`${glyph} ${open ? 'rotate-90 opacity-0' : ''}`} weight="regular" />
      <X className={`${glyph} ${open ? '' : '-rotate-90 opacity-0'}`} weight="regular" />
    </span>
  )
}

export function BookIcon({ className = '' }: IconProps) {
  return <BookOpen className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

/**
 * The Apple mark on the download button — the fastest way to say "this is a
 * macOS application" before anyone reads a word.
 */
export function AppleIcon({ className = '' }: IconProps) {
  return (
    <svg className={`${ICON} ${sized(className)} fill-current`} viewBox="0 0 16 16" aria-hidden="true">
      <path d="M11.03 8.52c-.02-1.6 1.31-2.37 1.37-2.41-.75-1.09-1.91-1.24-2.32-1.26-.99-.1-1.93.58-2.43.58-.5 0-1.27-.57-2.09-.55-1.07.02-2.06.62-2.61 1.58-1.11 1.93-.28 4.78.8 6.34.53.76 1.16 1.62 1.99 1.59.8-.03 1.1-.52 2.07-.52.96 0 1.24.52 2.09.5.86-.01 1.4-.78 1.93-1.55.61-.89.86-1.75.87-1.79-.02-.01-1.67-.64-1.69-2.54zM9.47 3.8c.44-.53.74-1.27.66-2.01-.63.03-1.4.42-1.86.95-.41.47-.77 1.23-.67 1.95.7.06 1.42-.36 1.87-.89z" />
    </svg>
  )
}

export function UploadIcon({ className = '' }: IconProps) {
  return <UploadSimple className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

/** The three kinds of file the hero demo cycles through. */
export function FileKindIcon({ kind, className = '' }: IconProps & { kind: 'image' | 'video' | 'pdf' }) {
  const Glyph = kind === 'image' ? ImageSquare : kind === 'video' ? FilmStrip : FilePdf
  return <Glyph className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}

/** One glyph per docs entry point on the landing page, keyed by slug. */
const DOC_GLYPHS = {
  'getting-started/quickstart': Lightning,
  'hosts/overview': HardDrives,
  'guide/templates': BracketsCurly,
  'guide/troubleshooting': Wrench,
} as const

export function DocIcon({ slug, className = '' }: IconProps & { slug: string }) {
  const Glyph = DOC_GLYPHS[slug as keyof typeof DOC_GLYPHS] ?? BookOpen
  return <Glyph className={`${ICON} ${sized(className)}`} weight="regular" aria-hidden />
}
