import { useEffect, useRef, useState } from 'react'

import { AppIcon, AppleIcon, FileKindIcon, UploadIcon } from './icons'
import { DROP_EVENT } from './HeroBackdrop'
import { prefersReducedMotion } from '../lib/motion'

/**
 * The hero: Dropline's whole job as one loop.
 *
 * A file drifts onto the drop zone, the menu bar icon runs its progress ring,
 * the link types itself into the clipboard and the notification answers. Then
 * the next file. Each cycle remounts the scene (`key={cycle}`), which restarts
 * the CSS timeline in app.css (`.demo*`); React only picks the sample.
 *
 * The un-animated styles are the finished frame, so with reduced motion — or
 * no JavaScript — the scene simply shows a completed upload.
 */

/* Every link is the same length, so one `steps(38)` typing rule fits all. */
const SAMPLES = [
  { name: 'shot.png', kind: 'image', link: 'cdn.example.com/2026/10/28/a1f3c9.png' },
  { name: 'demo.mp4', kind: 'video', link: 'cdn.example.com/2026/10/28/7be2d4.mp4' },
  { name: 'notes.pdf', kind: 'pdf', link: 'cdn.example.com/2026/10/28/c90f1a.pdf' },
] as const

const CYCLE_MS = 5500
/* When the file reaches the drop zone — 30% into the timeline */
const LAND_MS = 1650

export function HeroDemo({
  labels,
}: {
  labels: { drop: string; clipboard: string; copied: string; toast: string }
}) {
  const [cycle, setCycle] = useState(0)
  const ref = useRef<HTMLDivElement>(null)
  const sample = SAMPLES[cycle % SAMPLES.length]

  useEffect(() => {
    const el = ref.current
    if (!el || prefersReducedMotion() || typeof IntersectionObserver === 'undefined') return

    let timer = 0
    let landing = 0

    /* Tell the backdrop where the file landed, so the grid ripples from it */
    const land = () => {
      window.clearTimeout(landing)
      landing = window.setTimeout(() => {
        const box = el.querySelector('.demo__zone')?.getBoundingClientRect()
        if (!box) return
        const detail = { x: box.left + box.width / 2, y: box.top + box.height / 2 }
        window.dispatchEvent(new CustomEvent(DROP_EVENT, { detail }))
      }, LAND_MS)
    }

    const observer = new IntersectionObserver(([entry]) => {
      window.clearInterval(timer)
      window.clearTimeout(landing)
      if (entry.isIntersecting) {
        land()
        timer = window.setInterval(() => {
          setCycle((value) => value + 1)
          land()
        }, CYCLE_MS)
      }
    })
    observer.observe(el)

    return () => {
      observer.disconnect()
      window.clearInterval(timer)
      window.clearTimeout(landing)
    }
  }, [])

  return (
    <div ref={ref} className="relative" aria-hidden="true">
      <div key={cycle} className="demo relative rounded-2xl border border-rule bg-paper shadow-lift">
        {/* The menu bar, with Dropline's item on the right */}
        <div className="flex h-10 items-center justify-between rounded-t-2xl border-b border-rule bg-paper-2 px-4">
          <span className="flex items-center gap-3 text-xs font-semibold text-ink">
            <AppleIcon className="size-3.5" />
            Finder
          </span>
          <span className="flex items-center gap-3">
            <span className="h-2 w-8 rounded-sm bg-paper-3" />
            <span className="h-2 w-6 rounded-sm bg-paper-3" />
            <span className="relative grid size-6 place-items-center text-ink">
              <UploadIcon className="size-3.5" />
              <svg className="absolute inset-0 size-6 -rotate-90" viewBox="0 0 24 24">
                <circle className="demo__ring" cx="12" cy="12" r="10" />
              </svg>
            </span>
            <span className="tnum font-mono text-2xs text-muted">9:41</span>
          </span>
        </div>

        <div className="grid gap-4 p-4 sm:p-6">
          <div className="demo__zone grid h-48 place-items-center rounded-xl border-2 border-dashed border-rule-2 bg-paper-2">
            <span className="grid justify-items-center gap-2 text-sm text-muted">
              <UploadIcon className="size-8 text-neutral" />
              {labels.drop}
            </span>
          </div>

          <div className="rounded-lg border border-rule bg-paper-2 px-4 py-3">
            <span className="flex items-center justify-between">
              <span className="mono-label">{labels.clipboard}</span>
              <span className="demo__copied font-mono text-2xs text-accent">{labels.copied}</span>
            </span>
            <span className="mt-1 flex items-center font-mono text-xs text-ink sm:text-sm">
              <span className="demo__link">{sample.link}</span>
              <span className="caret" />
            </span>
          </div>
        </div>

        {/* The file in flight */}
        <span className="demo__file absolute inset-x-0 top-24 mx-auto flex w-max items-center gap-2 rounded-lg border border-rule bg-paper py-2 pr-4 pl-2 text-sm font-medium text-ink shadow-lift">
          <span className="grid size-8 place-items-center rounded-md bg-accent-wash text-accent">
            <FileKindIcon kind={sample.kind} />
          </span>
          {sample.name}
        </span>

        {/* The notification that closes the loop */}
        <span className="demo__toast absolute -top-6 right-2 flex sm:-right-4 items-center gap-3 rounded-xl border border-rule bg-paper/90 px-3 py-2 shadow-lift backdrop-blur-md">
          <AppIcon className="size-8" />
          <span className="grid">
            <span className="text-sm font-semibold text-ink">Dropline</span>
            <span className="text-xs text-muted">{labels.toast}</span>
          </span>
        </span>
      </div>
    </div>
  )
}
