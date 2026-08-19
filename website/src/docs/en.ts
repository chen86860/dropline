/** The English manual. Imported only by the `/docs` routes. */

import { DocSet, type DocModule } from './registry'

export const EN_DOCS = new DocSet(
  'en',
  import.meta.glob<DocModule>('./content/en/**/*.md', { eager: true }),
)
