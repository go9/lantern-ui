# Citation chip

Use `cite_chip` for inline evidence in Ask answers and attached draft context.
The same compact labels cover file:line, ticket `#N`, and memory references.
A chip opens the host's source preview; it does not navigate to the source itself.

```heex
<.cite_chip number={1} label="Open citation: lib/search.ex, lines 12–18"
  active={@source == "search"} id="cite-search"
  phx-click="preview" phx-value-source="search">
  search.ex:12–18
</.cite_chip>
<.cite_chip label="Open citation: ticket 212, Search scope"
  phx-click="preview" phx-value-source="ticket-212">#212</.cite_chip>
<.cite_chip label="Open citation: memory 167, Project scope policy"
  phx-click="preview" phx-value-source="memory-167">memory</.cite_chip>
```

`label` and the `inner_block` slot are required. `number` defaults to `nil`;
`active` defaults to `false`; `class` and global HTML/ARIA/`phx-*` attributes pass
through to the button. Numbering and full source names come from the host, so
no source registry or product-specific kind enum is required.

The native `type="button"` control supports Tab, Enter and Space and inherits
Lantern's button focus ring. The server owns `active` / `aria-pressed`; the host
owns preview rendering, dismissal and focus restoration. Set a stable chip `id`
when restoring focus after a modal preview. Add `aria-controls` only if that
preview target exists in the same rendered state. Do not add interactive slot
content. No motion or JS hook is added, including with reduced motion enabled.

Run the QA host (`MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs`)
and visit `/cite_chip` for working file, ticket, and memory examples with a
server-updated preview. Screenshot evidence is in `docs/qa-cite-chip/`.

The Ask spec requests numbered citations in prose and unnumbered draft context.
Sources/Buckets only specifies navigation from citations into the bucket;
Suggestions specifies evidence with temporal provenance. Those destinations
and provenance belong to their hosts; neither requires another chip variant.
