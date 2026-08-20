import { defineConfig } from 'vite'

import { tanstackStart } from '@tanstack/react-start/plugin/vite'

import viteReact from '@vitejs/plugin-react'
import { cloudflare } from '@cloudflare/vite-plugin'
import tailwindcss from '@tailwindcss/vite'

import { changelog } from './plugins/changelog'
import { markdown } from './plugins/markdown'
import { sitemap } from './plugins/sitemap'

const config = defineConfig({
  resolve: { tsconfigPaths: true },
  plugins: [
    cloudflare({ viteEnvironment: { name: 'ssr' } }),

    /* Markdown → HTML happens here, at build time, so the Worker ships no
       parser and the docs render as plain strings. Must run before anything
       else touches a `.md` id. */
    markdown(),
    /* Reads CHANGELOG.md from the repo root and serves it as a docs page. */
    changelog(),
    sitemap(),

    tailwindcss(),
    tanstackStart(),
    viteReact(),
  ],
})

export default config
