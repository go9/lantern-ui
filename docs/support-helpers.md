# Support helpers

These functions are helpers around LanternUI components, not components
themselves. They are documented here to make the boundary explicit. Unless a
function is marked public below, hosts should use the component API instead of
calling the helper directly. Internal helpers have no compatibility promise.

## Form

### `LanternUI.Components.Form.translate_error/1`

```elixir
translate_error({message, options}) :: String.t()
translate_error(message) when is_binary(message) :: String.t()
```

This host-facing helper interpolates `%{key}` bindings in a changeset error
tuple and returns a message string. It performs only interpolation; hosts that
use Gettext can translate messages before passing explicit `errors` to
`input/1`. The function is public and intended for form integration, but its
stability follows the component's current error contract rather than a separate
versioned API.

## DatePicker

### LanternUI.Components.DatePicker.canonical/2

```elixir
canonical(value, mode) :: String.t() | nil
```

This is the normalization step used by the date picker implementation. It
converts supported `Date`, `Time`, `NaiveDateTime`, and `DateTime` values to the
picker's canonical strings for `:date`, `:datetime`, or `:time` modes, while
empty values become `nil`. It is marked `@doc false` and is an internal support
helper. Hosts should pass `value` to `date_picker/1`, `date_time_picker/1`, or
`time_picker/1` instead of calling it.

## Pagination

### LanternUI.Components.Pagination.window/3

```elixir
window(page, total, sibling_count) :: [pos_integer() | :gap]
```

This internal helper builds the page-number window used by `pagination/1`,
including `:gap` markers between non-adjacent pages. It is marked `@doc false`.
Hosts should provide `meta` and `patch_fn` to `pagination/1`; the window
algorithm is not a public compatibility surface.

## DataTable URL helpers

### LanternUI.Components.DataTable.page_path/3

```elixir
page_path(path, meta, page_params) :: String.t()
```

Builds the pagination patch path from `meta.params`, replacing the page and
optionally the page size. It is marked `@doc false` and is used internally by
`data_table/1` and `Pagination.pagination/1`. Hosts should own URL construction
and pass a base `path` to the component.

### LanternUI.Components.DataTable.sort_path/3

```elixir
sort_path(path, meta, field) :: String.t()
```

Builds the sort patch path from the current query parameters, toggling the
direction when the requested field is already the only sort field and removing
the page parameter. It is marked `@doc false` and is an internal implementation
helper, not a host URL API.

### `LanternUI.Components.DataTable.sort_direction/2`

```elixir
sort_direction(meta, field) :: String.t()
```

Returns `"ascending"`, `"descending"`, or `"none"` for the requested field.
This public helper supplies the ARIA `sort` value for a sortable table header.
It is intended for host-owned table markup that follows the same `meta` shape;
the return values are the current component contract.

### LanternUI.Components.DataTable.sort_indicator/2

```elixir
sort_indicator(meta, field) :: String.t()
```

Returns the current visual arrow or an empty string for a field without the
active sort. It is marked `@doc false` and is used by `data_table/1`; hosts
should use the component's sortable column support rather than call it.

## Calendar

### LanternUI.Components.Calendar.weeks/2

```elixir
weeks(month_start, week_start) :: [[Date.t()]]
```

Builds the six-row calendar grid for the month and requested first weekday.
It is marked `@doc false` and is an internal rendering helper. Hosts should use
`calendar/1` or the picker components instead of depending on its grid shape.
