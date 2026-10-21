# Host badge

`use LanternUI` (or `use LanternUI, only: [:host_badge]`) imports `host_badge/1`.
It composes the existing small neutral `badge/1`, so host identity stays quiet
in resource tables, under titles, and beside choices in creation dialogs.

| Attribute | Contract |
|---|---|
| `host` | Required string; the display name, with no fixed provider catalog. |
| `coming_soon` | Boolean, default `false`; visible “Coming soon” and `aria-disabled="true"`. |
| `class` | Extra classes merged onto the root span. |
| global attributes | Passed through for IDs, data attributes, and ARIA annotations. |

There are no slots. No link target, click handler, icon, color, size, or health
option is built in. Treat it as text; do not add activation handlers or a
`tabindex`. The host name and availability are readable without color. The
server owns availability; there is no client state or motion. Keyboard users
skip the badge, and reduced-motion users see the same static content.

```heex
<.host_badge host="Flicker" />
<.host_badge host="Fly" coming_soon />
<.host_badge host="Neon" coming_soon />
```

The runnable demo is `/host_badge` on the repository's
`MIX_ENV=test mix run --no-halt test/qa/server.exs` host. It includes a resource
list and the shared picker pattern, with actual disabled radios. A badge's
ARIA state does not disable a parent control. See the
[recipe](recipes.md#host-identity-in-resource-lists-and-creation).
