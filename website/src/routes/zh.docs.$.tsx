import { createFileRoute } from '@tanstack/react-router'

import { DocsNotFound, DocsPage } from '../components/docs/DocsPage'
import { ZH_DOCS } from '../docs/zh'
import { docsHeadFor, docsNotFoundHead } from '../lib/docs-head'

/** `/zh/docs/*` — 中文手册的每一页。结构与英文路由一致。 */
export const Route = createFileRoute('/zh/docs/$')({
  head: ({ params }) => {
    const doc = ZH_DOCS.get(params._splat ?? '')
    return doc ? docsHeadFor('zh', doc, ZH_DOCS) : docsNotFoundHead('zh')
  },
  component: RouteComponent,
})

function RouteComponent() {
  const { _splat } = Route.useParams()
  const doc = ZH_DOCS.get(_splat ?? '')

  if (!doc) return <DocsNotFound lang="zh" docs={ZH_DOCS} />
  return <DocsPage lang="zh" docs={ZH_DOCS} doc={doc} />
}
