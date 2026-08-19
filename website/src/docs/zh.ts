/** 简体中文手册。只被 `/zh/docs` 路由引用。 */

import { DocSet, type DocModule } from './registry'

export const ZH_DOCS = new DocSet(
  'zh',
  import.meta.glob<DocModule>('./content/zh/**/*.md', { eager: true }),
)
