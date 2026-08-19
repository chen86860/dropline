import { createFileRoute } from '@tanstack/react-router'

import { DocsPage } from '../components/docs/DocsPage'
import { EN_DOCS } from '../docs/en'
import { docsHeadFor } from '../lib/docs-head'

/** `/docs` — the manual's own index page, compiled from `content/en/index.md`. */
const doc = EN_DOCS.get('')!

export const Route = createFileRoute('/docs/')({
  head: () => docsHeadFor('en', doc, EN_DOCS),
  component: () => <DocsPage lang="en" docs={EN_DOCS} doc={doc} />,
})
