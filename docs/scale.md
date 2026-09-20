# Compact type + grey roles

Dense app surfaces (ticket rows, inspectors, rails) used to pick `text-[11px]`,
`text-xs`, and one of five greys at random. These are the named sizes and the
four grey roles that replace that. `mix lantern.lint` fails the old patterns in
consuming apps.

## Type scale

Body copy stays `text-sm` / `--lantern-text`. These three extras are for chrome
that must stay denser than body.

| Class | Size | Leading | Tracking | Use |
|---|---|---|---|---|
| `text-meta` | 11px | 1.25 | 0.01em | Secondary metadata on a row: counts, relative time, status words, uppercase kickers (`uppercase tracking-wide` still applies on top). |
| `text-caption` | 12px | 1.35 | 0.005em | Helper text under a control, dense supporting copy in a rail or empty state. One step above meta, still below body. |
| `text-mono-meta` | 11px | 1.25 | 0 | Identifiers: ticket ids, SHAs, slugs, tabular numbers. Monospace + `tabular-nums`. |

Do not write `text-[Npx]`. Comfortable density (`data-lantern-density="comfortable"`)
bumps meta/mono-meta to 12px and caption to 13px.

`text-xs` (Tailwind 0.75rem) is still legal, but on a 14px root it is 10.5px and
is not a lantern size — prefer `text-caption` or `text-meta`.

## Grey roles

Four survive. `text-foreground-softer` is a **deprecated alias of
`text-foreground-soft`**: the class still compiles so existing markup does not
break; new code must not introduce it. Hosts that set `--foreground-softer`
themselves keep that colour until they stop.

| Class | Token | Role |
|---|---|---|
| `text-foreground` | `--foreground` | Primary content: titles, values, body. |
| `text-foreground-soft` | `--foreground-soft` | Secondary labels and supporting copy: property names, column headers, non-active nav. |
| `text-foreground-softest` | `--foreground-softest` | Tertiary meta: timestamps, ids, counts, decorative icons. |
| `text-muted-foreground` | `--muted-foreground` | Disabled, placeholder, and non-interactive chrome. Not a fifth decorative grey. |

`text-foreground-softer` → same token as `text-foreground-soft` in lantern
defaults. Do not use it in new markup.

Palette classes (`text-gray-500`, `bg-red-500`, …) and hex arbitrary values
(`text-[#71717a]`) are page-local greys. Use a role above, or `text-danger` /
`bg-success` / `text-warning` for status.

## Lint

From a consuming app, or against a path:

```bash
mix lantern.lint
mix lantern.lint ../flicker
```

Fails on `text-[Npx]`, `w-[Npx]` / `h-[Npx]` / `size-[Npx]` (and min/max),
Tailwind palette colours, and hex arbitrary colours in `.ex` / `.exs` / `.heex`.

Allowlist:

- `.lantern-lint.json` in the scanned root:

  ```json
  { "exclude": ["priv/**"], "allow": ["lib/vendor/**"] }
  ```

- Same line or previous line: `lantern-lint:ignore`
