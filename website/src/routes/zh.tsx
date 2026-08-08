import { createFileRoute } from '@tanstack/react-router'

import { Landing } from '../components/Landing'
import { headFor } from '../lib/head'

export const Route = createFileRoute('/zh')({
  head: () => headFor('zh'),
  component: () => <Landing lang="zh" />,
})
