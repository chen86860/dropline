/** One icon set, one stroke weight, one corner style — never mixed. */

type IconProps = { className?: string }

const STROKE = 'size-[15px] shrink-0 fill-none stroke-current stroke-[1.6]'

export function ArrowIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M3 8h10" />
      <path d="M9 4l4 4-4 4" />
    </svg>
  )
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
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <circle cx="7" cy="7" r="4.25" />
      <path d="M10.2 10.2 13.5 13.5" />
    </svg>
  )
}

export function ChevronIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M6 3.5 10.5 8 6 12.5" />
    </svg>
  )
}

export function MenuIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <path d="M2.5 4.5h11" />
      <path d="M2.5 8h11" />
      <path d="M2.5 11.5h11" />
    </svg>
  )
}

export function CloseIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <path d="M4 4l8 8" />
      <path d="M12 4l-8 8" />
    </svg>
  )
}

export function BookIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`${STROKE} ${className}`}
      viewBox="0 0 16 16"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M2.5 3.5A1 1 0 0 1 3.5 2.5H7a1.5 1.5 0 0 1 1.5 1.5v9A1.2 1.2 0 0 0 7.3 12H3.5a1 1 0 0 1-1-1z" />
      <path d="M13.5 3.5a1 1 0 0 0-1-1H9A1.5 1.5 0 0 0 7.5 4v9A1.2 1.2 0 0 1 8.7 12h3.8a1 1 0 0 0 1-1z" />
    </svg>
  )
}

/**
 * The Apple mark on the download button — the fastest way to say "this is a
 * macOS application" before anyone reads a word.
 */
export function AppleIcon({ className = '' }: IconProps) {
  return (
    <svg
      className={`size-4 shrink-0 fill-current ${className}`}
      viewBox="0 0 16 16"
      aria-hidden="true"
    >
      <path d="M11.03 8.52c-.02-1.6 1.31-2.37 1.37-2.41-.75-1.09-1.91-1.24-2.32-1.26-.99-.1-1.93.58-2.43.58-.5 0-1.27-.57-2.09-.55-1.07.02-2.06.62-2.61 1.58-1.11 1.93-.28 4.78.8 6.34.53.76 1.16 1.62 1.99 1.59.8-.03 1.1-.52 2.07-.52.96 0 1.24.52 2.09.5.86-.01 1.4-.78 1.93-1.55.61-.89.86-1.75.87-1.79-.02-.01-1.67-.64-1.69-2.54zM9.47 3.8c.44-.53.74-1.27.66-2.01-.63.03-1.4.42-1.86.95-.41.47-.77 1.23-.67 1.95.7.06 1.42-.36 1.87-.89z" />
    </svg>
  )
}
