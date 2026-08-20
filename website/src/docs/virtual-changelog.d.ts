/**
 * The changelog pages are compiled from `CHANGELOG.md` / `CHANGELOG.zh-CN.md`
 * at the repository root by `plugins/changelog.ts`, and reach the bundle as
 * virtual modules rather than files under `content/`.
 */

declare module 'virtual:dropline-changelog/en' {
  const doc: import('./registry').DocModule
  export default doc
}

declare module 'virtual:dropline-changelog/zh' {
  const doc: import('./registry').DocModule
  export default doc
}
