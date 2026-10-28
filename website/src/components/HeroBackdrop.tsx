import { useEffect, useRef } from 'react'

import { prefersReducedMotion } from '../lib/motion'

/**
 * The hero's ground: a faint grid that ripples outward whenever a file lands.
 *
 * After Aceternity's "Background Ripple Effect", drawn on one canvas instead of
 * hundreds of cells. A ripple starts on every `dropline:drop` event (the hero
 * demo fires one as its file reaches the drop zone) and on every click in the
 * hero; the cell under the pointer lights up faintly. The frame loop only runs
 * while something is moving. Under reduced motion it is a still grid.
 */

const CELL = 48
const SPEED = 0.6 // px per ms
const BAND = 96 // width of the ripple ring, px
const LIFE = 2200 // ms

type Ripple = { x: number; y: number; t0: number }

export const DROP_EVENT = 'dropline:drop'

export function HeroBackdrop() {
  const ref = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = ref.current
    const host = canvas?.parentElement
    const ctx = canvas?.getContext('2d')
    if (!canvas || !host || !ctx) return

    const style = getComputedStyle(document.documentElement)
    const rule = style.getPropertyValue('--color-rule').trim()
    const accent = style.getPropertyValue('--color-accent').trim()
    const still = prefersReducedMotion()

    let width = 0
    let height = 0
    let frame = 0
    let hover: { col: number; row: number } | null = null
    const ripples: Ripple[] = []

    function draw(now: number) {
      frame = 0
      ctx!.clearRect(0, 0, width, height)

      // Ripple and hover fills, under the lines
      for (let i = ripples.length - 1; i >= 0; i--) {
        if (now - ripples[i].t0 > LIFE) ripples.splice(i, 1)
      }
      const cols = Math.ceil(width / CELL)
      const rows = Math.ceil(height / CELL)
      ctx!.fillStyle = accent
      for (let row = 0; row < rows; row++) {
        for (let col = 0; col < cols; col++) {
          const cx = col * CELL + CELL / 2
          const cy = row * CELL + CELL / 2
          let level = 0
          for (const ripple of ripples) {
            const age = now - ripple.t0
            const ring = age * SPEED
            const d = Math.hypot(cx - ripple.x, cy - ripple.y)
            const hit = 1 - Math.abs(d - ring) / BAND
            if (hit > 0) level = Math.max(level, hit * (1 - age / LIFE))
          }
          if (hover && hover.col === col && hover.row === row) level = Math.max(level, 0.35)
          if (level > 0) {
            ctx!.globalAlpha = level * 0.4
            ctx!.fillRect(col * CELL + 1, row * CELL + 1, CELL - 1, CELL - 1)
          }
        }
      }

      // The grid itself
      ctx!.globalAlpha = 1
      ctx!.strokeStyle = rule
      ctx!.lineWidth = 1
      ctx!.beginPath()
      for (let x = 0.5; x <= width; x += CELL) {
        ctx!.moveTo(x, 0)
        ctx!.lineTo(x, height)
      }
      for (let y = 0.5; y <= height; y += CELL) {
        ctx!.moveTo(0, y)
        ctx!.lineTo(width, y)
      }
      ctx!.stroke()

      if (ripples.length) frame = requestAnimationFrame(draw)
    }

    function schedule() {
      if (!frame) frame = requestAnimationFrame(draw)
    }

    function resize() {
      const ratio = window.devicePixelRatio || 1
      width = host!.clientWidth
      height = host!.clientHeight
      canvas!.width = width * ratio
      canvas!.height = height * ratio
      ctx!.setTransform(ratio, 0, 0, ratio, 0, 0)
      schedule()
    }

    const sizer = new ResizeObserver(resize)
    sizer.observe(host)
    resize()

    if (still) return () => sizer.disconnect()

    function local(clientX: number, clientY: number) {
      const box = host!.getBoundingClientRect()
      return { x: clientX - box.left, y: clientY - box.top }
    }

    function ripple(clientX: number, clientY: number) {
      ripples.push({ ...local(clientX, clientY), t0: performance.now() })
      schedule()
    }

    const onDrop = (event: Event) => {
      const { x, y } = (event as CustomEvent<{ x: number; y: number }>).detail
      ripple(x, y)
    }
    const onDown = (event: PointerEvent) => ripple(event.clientX, event.clientY)
    const onMove = (event: PointerEvent) => {
      const { x, y } = local(event.clientX, event.clientY)
      const next = { col: Math.floor(x / CELL), row: Math.floor(y / CELL) }
      if (hover?.col === next.col && hover?.row === next.row) return
      hover = next
      schedule()
    }
    const onLeave = () => {
      hover = null
      schedule()
    }

    window.addEventListener(DROP_EVENT, onDrop)
    host.addEventListener('pointerdown', onDown)
    host.addEventListener('pointermove', onMove)
    host.addEventListener('pointerleave', onLeave)

    return () => {
      sizer.disconnect()
      cancelAnimationFrame(frame)
      window.removeEventListener(DROP_EVENT, onDrop)
      host.removeEventListener('pointerdown', onDown)
      host.removeEventListener('pointermove', onMove)
      host.removeEventListener('pointerleave', onLeave)
    }
  }, [])

  return <canvas ref={ref} className="hero-backdrop" aria-hidden="true" />
}
