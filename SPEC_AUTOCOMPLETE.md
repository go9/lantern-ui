# Spec: autocomplete (client-side typeahead, Fluxon v2 parity)

## Objective

Add `LanternUI.Components.Autocomplete.autocomplete/1` mirroring Fluxon's
autocomplete for the CLIENT-SIDE case (filter a provided `options` list as the
user types; no async `on_search` — that's a later addition). This unblocks
skusync, whose only usage passes a static `options` list. It is essentially the
searchable `select` but with a free-text `<input>` as the trigger instead of a
button.

STUDY FIRST: `lib/lantern_ui/components/select.ex` (the rich `select/1` clause
with the FormField handling, hidden value input, listbox + options) and the
`LanternSelect` hook in `priv/static/lantern_ui_hooks.js` (positioning,
keyboard nav, type-ahead, onDismiss). Adapt that pattern; do not reinvent
positioning — reuse the `position` / `onDismiss` runtime helpers.

## API (Fluxon-parity subset)

attrs: `id`, `name`, `value` (current selected value), `field`
(Phoenix.HTML.FormField, default nil — derive id/name/value/errors exactly like
select.ex's FormField clause), `options` (:list — strings, atoms, numbers, or
{label, value} tuples), `label`, `sublabel`, `description`, `help_text`,
`placeholder` (default "Search…"), `size` (:string, default "md"), `disabled`,
`errors` (:list, default []), `search_threshold` (:integer, default nil —
accepted for compat), `no_results_text` (:string, default "No results"),
`class`, `rest` (:global include ~w(form phx-change phx-target)).
Every attr/slot gets a concise `doc:`.

## Render

A `lui-field` wrapper (label / sublabel / description via
LanternUI.Components.Form.label, error/help like select.ex), then:

    <div id={"#{@id}-ac"} class="lui-autocomplete" phx-hook="LanternAutocomplete"
         data-name={@name}>
      <input type="hidden" name={@name} value={@value_s} data-part="value" {form/phx-* rest} />
      <div class="lui-autocomplete-control">
        <input type="text" id={@id} class="lui-autocomplete-input" data-part="input"
               placeholder={@placeholder} autocomplete="off" role="combobox"
               aria-expanded="false" aria-autocomplete="list" value={selected_label(@opts,@value_s)} />
        <Icon.icon name="chevron-up-down" class="lui-select-caret" />
      </div>
      <div class="lui-select-listbox" data-part="panel" role="listbox" hidden tabindex="-1">
        <button :for={{label,value} <- @opts} type="button" class="lui-select-option"
                role="option" data-part="option" data-value={value}
                aria-selected={to_string(to_string(value)==@value_s)}>
          <span class="lui-select-option-label">{label}</span>
          <Icon.icon name="check" class="lui-select-check" />
        </button>
        <p class="lui-select-noresults" data-part="no-results" hidden>{@no_results_text}</p>
      </div>
    </div>

Reuse the existing `.lui-select-listbox` / `.lui-select-option` / `.lui-select-noresults`
CSS (already styled). Only add minimal new CSS for `.lui-autocomplete`,
`.lui-autocomplete-control` (like `.lui-select-toggle` box: border, height
var(--lantern-control-h), caret), `.lui-autocomplete-input` (borderless fill).

Helper `option_pair/1`, `selected_label/2` mirror select.ex (copy the private
helpers or extract — keep it simple, duplication is fine here).

## LanternAutocomplete hook (priv/static/lantern_ui_hooks.js)

Model it on `LanternSelect`, but:
- Typing in the text input opens the panel and filters options: an option is
  hidden unless its label includes the query (case-insensitive); show the
  no-results element when none match.
- ArrowDown/Up move through VISIBLE options; Enter/click selects: set the
  hidden value input (dispatch input+change), set the text input's value to the
  option label, close the panel.
- Escape closes; onDismiss (outside click) closes and, if the text doesn't
  match the selected label, restores the selected label (don't leave a dangling
  query).
- aria-expanded on the input reflects open state.
Export it in BOTH the Hooks object and the named export list, next to
LanternSelect. `node --check` must pass.

## Register + tests

- lib/lantern_ui.ex @components: `autocomplete: LanternUI.Components.Autocomplete`.
- test/lantern_ui/autocomplete_test.exs: renders hook + hidden value + text
  input (role=combobox) + options + no-results element; FormField clause
  extracts name/value; selected value prefills the input label.
- test/lantern_ui/components_test.exs: add `:autocomplete` to the sorted key
  assertion (first, before :badge).

## Constraints

- Additive; don't change select.ex or other components.
- mix format ONLY changed files. node --check the hooks file.

## Verification (run; all pass)

    mix compile --warnings-as-errors
    mix test
    node --check priv/static/lantern_ui_hooks.js

Do not commit.
