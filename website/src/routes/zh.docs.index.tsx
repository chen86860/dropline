import { createFileRoute } from '@tanstack/react-router'

import { DocsPage } from '../components/docs/DocsPage'
import { ZH_DOCS } from '../docs/zh'
import { docsHeadFor } from '../lib/docs-head'

/** `/zh/docs` — 中文手册首页，来自 `content/zh/index.md`。 */
const doc = ZH_DOCS.get('')!

export const Route = createFileRoute('/zh/docs/')({
  head: () => docsHeadFor('zh', doc, ZH_DOCS),
  component: () => <DocsPage lang="zh" docs={ZH_DOCS} doc={doc} />,
})
