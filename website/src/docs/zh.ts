/** 简体中文手册。只被 `/zh/docs` 路由引用。 */

import changelog from 'virtual:dropline-changelog/zh'

import { DocSet, type DocModule } from './registry'

export const ZH_DOCS = new DocSet('zh', {
  ...import.meta.glob<DocModule>('./content/zh/**/*.md', { eager: true }),
  /* 由仓库根目录的 CHANGELOG.zh-CN.md 编译而来，不在这里另存一份 ——
     见 `plugins/changelog.ts`。并进 DocSet 之后，侧边栏、搜索、翻页、
     head 标签都自动具备。 */
  './content/zh/changelog.md': changelog,
})
