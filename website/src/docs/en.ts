/** The English manual. Imported only by the `/docs` routes. */

import changelog from 'virtual:dropline-changelog/en'

import { DocSet, type DocModule } from './registry'

export const EN_DOCS = new DocSet('en', {
  ...import.meta.glob<DocModule>('./content/en/**/*.md', { eager: true }),
  /* Compiled from CHANGELOG.md at the repo root rather than kept as a copy —
     see `plugins/changelog.ts`. Joining the set here is what gives it the
     sidebar, the search index, the pager and the head tags. */
  './content/en/changelog.md': changelog,
})
