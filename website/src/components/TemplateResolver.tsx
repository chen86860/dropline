import { useEffect, useRef, useState } from 'react'

import { prefersReducedMotion } from '../lib/motion'

/**
 * The object key template, filling itself in.
 *
 * Each `{{variable}}` turns into the value it renders to, one after another,
 * and once the key is complete the final URL picks it up — the same order
 * Dropline evaluates them in. It loops while on screen. The server renders the
 * raw template; under reduced motion the finished result is shown at once.
 *
 * Sample values follow the formats in the template docs.
 */

const SAMPLE: Record<string, string> = {
  date: '2026/10/28',
  uuid: 'a1f3c9e04b7d',
  ext: 'png',
  base: 'shot',
  filename: 'shot.png',
  rand: '4821',
}

const STEP_MS = 700
const HOLD_MS = 3200

type Token = { text: string; name?: string }

function tokenize(template: string): Token[] {
  return template
    .split(/(\{\{\w+\}\})/)
    .filter(Boolean)
    .map((text) => {
      const name = /^\{\{(\w+)\}\}$/.exec(text)?.[1]
      return name ? { text, name } : { text }
    })
}

export function TemplateResolver({
  keyLabel,
  keyTemplate,
  urlLabel,
  urlTemplate,
  varsLabel,
  vars,
}: {
  keyLabel: string
  keyTemplate: string
  urlLabel: string
  urlTemplate: string
  varsLabel: string
  vars: string[]
}) {
  const keyTokens = tokenize(keyTemplate)
  const total = keyTokens.filter((token) => token.name).length
  const resolvedKey = keyTokens.map((token) => (token.name ? SAMPLE[token.name] : token.text)).join('')

  /* How many variables have resolved so far; `total` means the key is done. */
  const [done, setDone] = useState(0)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const el = ref.current
    if (!el) return

    if (prefersReducedMotion() || typeof IntersectionObserver === 'undefined') {
      setDone(total)
      return
    }

    let timer = 0
    let count = 0
    const tick = () => {
      count = count >= total ? 0 : count + 1
      setDone(count)
      timer = window.setTimeout(tick, count >= total ? HOLD_MS : STEP_MS)
    }

    const observer = new IntersectionObserver(([entry]) => {
      window.clearTimeout(timer)
      if (entry.isIntersecting) timer = window.setTimeout(tick, STEP_MS)
    })
    observer.observe(el)

    return () => {
      observer.disconnect()
      window.clearTimeout(timer)
    }
  }, [total])

  /* Position of each token among the variables, so the nth resolves nth */
  const order = keyTokens.map((token, index) =>
    token.name ? keyTokens.slice(0, index).filter((prior) => prior.name).length : -1,
  )
  const complete = done >= total

  return (
    <div
      ref={ref}
      className="grid gap-4 rounded-lg border border-graphite-rule bg-graphite-2 p-6 font-mono text-xs"
    >
      <div className="grid gap-1">
        <span className="mono-label text-graphite-muted">{keyLabel}</span>
        <span className="break-anywhere text-graphite-ink">
          {keyTokens.map((token, index) => {
            if (!token.name) return <span key={index}>{token.text}</span>
            const resolved = order[index] < done
            return (
              <span
                key={index}
                className={[
                  'rounded-sm transition-colors duration-micro ease-out',
                  resolved ? 'bg-accent-soft/15 text-accent-soft' : 'text-graphite-muted',
                ].join(' ')}
              >
                {resolved ? SAMPLE[token.name] : token.text}
              </span>
            )
          })}
        </span>
      </div>

      <div className="grid gap-1">
        <span className="mono-label text-graphite-muted">{urlLabel}</span>
        <span className="break-anywhere text-graphite-ink">
          {urlTemplate.replace('{{key}}', '')}
          <span
            className={[
              'transition-colors duration-micro ease-out',
              complete ? 'text-accent-soft' : 'text-graphite-muted',
            ].join(' ')}
          >
            {complete ? resolvedKey : '{{key}}'}
          </span>
        </span>
      </div>

      <div className="grid gap-2 border-t border-graphite-rule pt-4">
        <span className="mono-label text-graphite-muted">{varsLabel}</span>
        <ul className="flex flex-wrap gap-1">
          {vars.map((name) => (
            <li
              key={name}
              className="rounded-sm border border-graphite-rule px-2 py-0.5 text-2xs whitespace-nowrap text-graphite-muted"
            >
              {name}
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
