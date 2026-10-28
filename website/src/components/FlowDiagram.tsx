import { AppIcon } from './icons'

/**
 * "Five ways in. One way out." drawn as what it says: five entry points
 * converging on the app, and a single line out to the clipboard.
 *
 * The labels repeat the list beside it, so the whole drawing is decorative to
 * assistive tech. Packets travel each line toward the app; under reduced
 * motion they are hidden (see `.flow__pulse` in app.css).
 */

const W = 600
const H = 320
const NODE_W = 128
const NODE_H = 40
const HUB = { x: 316, y: H / 2, r: 36 }
const OUT = { x: 392, w: 208, h: 64 }

export function FlowDiagram({
  inputs,
  output,
}: {
  inputs: string[]
  output: { label: string; url: string }
}) {
  const gap = (H - NODE_H) / (inputs.length - 1)

  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      className="mx-auto h-auto w-full max-w-2xl overflow-visible"
      aria-hidden="true"
    >
      {inputs.map((label, index) => {
        const y = index * gap
        const cy = y + NODE_H / 2
        const from = NODE_W
        const to = HUB.x - HUB.r
        const mid = (from + to) / 2
        return (
          <g key={label}>
            <path
              className="flow__line"
              d={`M${from} ${cy} C${mid} ${cy} ${mid} ${HUB.y} ${to} ${HUB.y}`}
            />
            {/* A packet travelling the line, staggered per input */}
            <circle r={3} className="flow__pulse">
              <animateMotion
                dur="2.4s"
                begin={`${index * 0.48}s`}
                repeatCount="indefinite"
                keyTimes="0;1"
                keySplines="0.22 1 0.36 1"
                calcMode="spline"
                path={`M${from} ${cy} C${mid} ${cy} ${mid} ${HUB.y} ${to} ${HUB.y}`}
              />
            </circle>
            <rect
              x={0.5}
              y={y + 0.5}
              width={NODE_W - 1}
              height={NODE_H - 1}
              rx={8}
              className="fill-paper stroke-rule-2"
            />
            <text
              x={16}
              y={cy}
              dominantBaseline="central"
              className="fill-ink-2 font-mono text-sm"
            >
              {label}
            </text>
          </g>
        )
      })}

      {/* The app — the one place the paths meet */}
      <circle cx={HUB.x} cy={HUB.y} r={HUB.r + 12} className="fill-accent-wash" />
      <svg x={HUB.x - HUB.r} y={HUB.y - HUB.r} width={HUB.r * 2} height={HUB.r * 2}>
        <AppIcon className="size-full" />
      </svg>

      {/* The single way out */}
      <path className="flow__line flow__line--out" d={`M${HUB.x + HUB.r} ${HUB.y} H${OUT.x}`} />
      <circle r={3} className="flow__pulse">
        <animateMotion
          dur="1.2s"
          repeatCount="indefinite"
          path={`M${HUB.x + HUB.r} ${HUB.y} H${OUT.x}`}
        />
      </circle>
      <rect
        x={OUT.x + 0.5}
        y={HUB.y - OUT.h / 2 + 0.5}
        width={OUT.w - 1}
        height={OUT.h - 1}
        rx={12}
        className="fill-paper stroke-accent"
      />
      <text
        x={OUT.x + 16}
        y={HUB.y - 8}
        className="fill-ink text-base font-semibold"
      >
        {output.label}
      </text>
      <text x={OUT.x + 16} y={HUB.y + 16} className="fill-muted font-mono text-2xs">
        {output.url}
      </text>
    </svg>
  )
}
