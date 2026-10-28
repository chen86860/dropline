import type { ElementType, ReactNode } from 'react'

import { useReveal } from '../lib/motion'

/**
 * Fades and lifts its contents into place the first time they approach the
 * viewport, then stops caring.
 *
 * The children are always in the DOM and always in the server response — the
 * only thing this changes is opacity and a few pixels of transform, and only
 * when both JavaScript and motion are welcome. See `.reveal` in app.css.
 */
export function Reveal({
  as: Tag = 'div',
  step = 0,
  className = '',
  children,
  ...rest
}: {
  as?: ElementType
  /** Stagger position (0–4) for items revealed as a group, 80ms apart. */
  step?: number
  className?: string
  children: ReactNode
  [key: string]: unknown
}) {
  const ref = useReveal<HTMLElement>()

  return (
    <Tag
      ref={ref}
      data-reveal=""
      className={className}
      data-step={step ? Math.min(step, 4) : undefined}
      {...rest}
    >
      {children}
    </Tag>
  )
}
