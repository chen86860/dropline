import { Link, type LinkComponentProps } from '@tanstack/react-router'

/**
 * A `<Link>` whose destination is computed rather than written out.
 *
 * TanStack Router types `to` as the union of the routes it generated, which is
 * exactly what you want when a link is a literal. Docs links are not literals:
 * they come from the file tree, through the splat route `/docs/$`, so the
 * concrete path is only known at runtime. The router resolves such a path
 * against the tree perfectly well — it is the *type* that cannot see it.
 *
 * So the cast lives here, once, with this note, instead of at every call site.
 * If the path does not match a route the router will say so at runtime, which
 * is the same failure mode a mistyped literal has.
 */
export function AppLink({
  href,
  ...props
}: { href: string } & Omit<LinkComponentProps<'a'>, 'to' | 'href'>) {
  return <Link {...props} to={href as never} />
}
