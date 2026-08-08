import { createFileRoute } from '@tanstack/react-router'

import { Landing } from '../components/Landing'
import { headFor } from '../lib/head'

export const Route = createFileRoute('/')({
  head: () => headFor('en'),
  component: () => <Landing lang="en" />,
})
