/**
 * The sidebar, and with it the reading order of the manual.
 *
 * Only slugs live here — every page title comes from its own frontmatter, so a
 * title is written once and cannot drift between the sidebar, the `<title>`
 * tag and the page's own heading. Group labels are the exception: they name a
 * section rather than a file, so they carry their own translations.
 */

import type { Lang } from '../content'

export interface DocGroup {
  id: string
  label: Record<Lang, string>
  items: string[]
}

export const DOC_GROUPS: DocGroup[] = [
  {
    id: 'start',
    label: { en: 'Getting started', zh: '开始使用' },
    items: ['getting-started/install', 'getting-started/quickstart'],
  },
  {
    id: 'guide',
    label: { en: 'Guide', zh: '使用手册' },
    items: [
      'guide/upload-methods',
      'guide/settings',
      'guide/templates',
      'guide/response',
      'guide/security',
      'guide/troubleshooting',
      'guide/build-from-source',
    ],
  },
  {
    id: 'hosts',
    label: { en: 'Host configuration', zh: '图床配置' },
    items: [
      'hosts/overview',
      'hosts/s3',
      'hosts/r2',
      'hosts/oss',
      'hosts/cos',
      'hosts/minio',
      'hosts/smms',
      'hosts/imgur',
      'hosts/lsky-chevereto',
      'hosts/easyimage',
      'hosts/custom-multipart',
      'hosts/custom-binary',
    ],
  },
  {
    id: 'releases',
    label: { en: 'Release notes', zh: '发布说明' },
    items: ['changelog'],
  },
]

/** Strings the docs chrome needs that do not come from a Markdown file. */
export const DOCS_UI: Record<
  Lang,
  {
    label: string
    tagline: string
    home: string
    sidebar: string
    onThisPage: string
    menu: string
    prev: string
    next: string
    edit: string
    search: string
    searchPlaceholder: string
    searchEmpty: string
    searchHint: string
    searchOpen: string
    breadcrumb: string
    notFoundTitle: string
    notFoundBody: string
    notFoundCta: string
    copy: string
    copied: string
    download: string
  }
> = {
  en: {
    label: 'Docs',
    tagline: 'Manual and host configuration for Dropline.',
    home: 'Home',
    sidebar: 'Documentation',
    onThisPage: 'On this page',
    menu: 'Browse the docs',
    prev: 'Previous',
    next: 'Next',
    edit: 'Edit this page on GitHub',
    search: 'Search the docs',
    searchPlaceholder: 'Search the docs…',
    searchEmpty: 'Nothing matched that.',
    searchHint: '↑↓ to move · ⏎ to open · esc to close',
    searchOpen: 'Search',
    breadcrumb: 'Breadcrumb',
    notFoundTitle: 'That page does not exist.',
    notFoundBody:
      'The manual may have been reorganised since that link was written. The index lists every page.',
    notFoundCta: 'Go to the docs index',
    copy: 'Copy',
    copied: 'Copied',
    download: 'Download',
  },
  zh: {
    label: '文档',
    tagline: 'Dropline 使用手册与图床配置说明。',
    home: '首页',
    sidebar: '文档目录',
    onThisPage: '本页目录',
    menu: '浏览文档',
    prev: '上一页',
    next: '下一页',
    edit: '在 GitHub 上编辑本页',
    search: '搜索文档',
    searchPlaceholder: '搜索文档…',
    searchEmpty: '没有匹配的结果。',
    searchHint: '↑↓ 切换 · ⏎ 打开 · esc 关闭',
    searchOpen: '搜索',
    breadcrumb: '面包屑导航',
    notFoundTitle: '这个页面不存在。',
    notFoundBody: '文档结构可能调整过。目录页里列着全部页面。',
    notFoundCta: '回到文档首页',
    copy: '复制',
    copied: '已复制',
    download: '下载',
  },
}
