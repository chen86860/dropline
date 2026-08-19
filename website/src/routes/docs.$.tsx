import { createFileRoute } from '@tanstack/react-router'

import { DocsNotFound, DocsPage } from '../components/docs/DocsPage'
import { EN_DOCS } from '../docs/en'
import { docsHeadFor, docsNotFoundHead } from '../lib/docs-head'

/**
 * `/docs/*` — every English manual page.
 *
 * One splat route rather than a file per page: the pages are data, and a route
 * per Markdown file would be twenty-odd files that only differ by a string.
 * Both the head tags and the body resolve from the same registry lookup, so a
 * page cannot be rendered with another page's metadata.
 */
export const Route = createFileRoute('/docs/$')({
  head: ({ params }) => {
    const doc = EN_DOCS.get(params._splat ?? '')
    return doc ? docsHeadFor('en', doc, EN_DOCS) : docsNotFoundHead('en')
  },
  component: RouteComponent,
})

function RouteComponent() {
  const { _splat } = Route.useParams()
  const doc = EN_DOCS.get(_splat ?? '')

  if (!doc) return <DocsNotFound lang="en" docs={EN_DOCS} />
  return <DocsPage lang="en" docs={EN_DOCS} doc={doc} />
}
