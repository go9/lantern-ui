defmodule LanternUI.Components.Select do
  @moduledoc """
  Select — mirrors Fluxon's `select/1` surface: a `FormField`-aware select with
  a rich listbox path and a `native` fallback.

      <.select field={@form[:channel]} label="Channel" options={["eBay", "Shopify"]} />
      <.select name="page_size" value="25" options={[10, 25, 50]} native />
      <.select field={@form[:status]} options={[{"Active", "active"}, {"Archived", "archived"}]} placeholder="Any status" />

  Options are strings, atoms, numbers, or `{label, value}` tuples. The rich
  path renders a button + listbox popover (LanternSelect hook: positioning,
  focus, ↑/↓/Home/End/Enter/Esc, type-ahead) over a hidden input carrying the
  value — form semantics identical to the native path.

  The non-searchable rich path is Zag-driven (a `@zag-js/select` state
  machine, loaded on demand): the hook root carries `data-zag` plus
  `data-scope="select"` / `data-part` anatomy, and Zag owns open state,
  keyboard, type-ahead, and ARIA. Styling stays `lui-*` tokens. Two modes:

    * client (default) — Zag owns the value from `data-default-value`;
      picks sync the hidden `<select>` and fire `input`/`change`, so an
      existing `phx-change` keeps working with no server round trip.
    * server-driven (`controlled`) — the server value (`data-value`) is
      truth; patches flow into the machine, client picks flow out through
      `on_change` (and the hidden input as usual).

  `searchable` adds a search box to the listbox (client-side filtering; or set
  `search_threshold` to auto-enable at N options). The searchable listbox
  stays on the legacy hook for now — it is not Zag-driven. `multiple` turns
  the picker into a multi-select: options toggle, the panel stays open, the
  toggle shows a count, and one hidden `name[]` input is submitted per
  selected value. Fluxon's `on_search` (server-driven options) is not yet
  implemented.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:id, :any,
    default: nil,
    doc: """
    Element id. Derived from `field` when omitted. With a bare `name` and no
    `field`, the rich path falls back to `name` (the id feeds a hook, so it must
    stay stable) while `native` auto-generates a unique `lui-select-<n>`,
    mirroring Fluxon. Pass an explicit id to get a stable, predictable id on the
    native path.
    """
  )

  attr(:name, :any, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Selected value(s); list when multiple.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:options, :list, default: [], doc: "Choices as values or {label, value} tuples.")
  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label line under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")

  attr(:help_text, :string,
    default: nil,
    doc: "Trailing help line under the field when no errors."
  )

  attr(:placeholder, :string, default: "Select…", doc: "Toggle text when nothing is selected.")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Control density / type scale."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")

  attr(:native, :boolean,
    default: false,
    doc: "Use a native <select> instead of the rich listbox."
  )

  attr(:include_hidden, :boolean,
    default: true,
    doc: "Emit a blank hidden input so empty submits."
  )

  attr(:prompt, :string, default: nil, doc: "blank first option (native path)")
  attr(:searchable, :boolean, default: false, doc: "search box inside the listbox")
  attr(:search_threshold, :integer, default: nil, doc: "auto-enable search at N+ options")

  attr(:search_input_placeholder, :string,
    default: "Search…",
    doc: "Placeholder for the listbox search input."
  )

  attr(:search_no_results_text, :string,
    default: "No results",
    doc: "Empty-state copy when search matches nothing."
  )

  attr(:multiple, :boolean, default: false, doc: "multi-select; submits name[] hidden inputs")
  attr(:max, :integer, default: nil, doc: "max selections when multiple")

  attr(:clearable, :boolean,
    default: false,
    doc: "show a clear (×) button that resets the selection (Fluxon parity)."
  )

  attr(:controlled, :boolean,
    default: false,
    doc:
      "server-driven mode: the server `value` is truth and patches flow into the Zag machine (non-searchable rich path only)."
  )

  attr(:on_change, :string,
    default: nil,
    doc:
      "server event pushed with `%{id, value}` when the Zag select value changes (non-searchable rich path only)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc:
      "bubbling DOM CustomEvent dispatched with `%{id, value}` on Zag value changes (non-searchable rich path only)."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(form phx-change phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  def select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> select()
  end

  def select(%{native: true} = assigns) do
    assigns = normalize(assigns)

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>
      <div class="lui-select-native-wrap">
        <select
          id={@id}
          name={@name}
          disabled={@disabled}
          class={["lui-select-native", @errors != [] && "lui-invalid"]}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          <option :for={{label, value} <- @opts} value={value} selected={to_string(value) == @value_s}>
            {label}
          </option>
        </select>
        <Icon.icon name="chevron-up-down" class="lui-select-caret" />
      </div>
      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
      <p :if={@help_text && @errors == []} class="lui-help">{@help_text}</p>
    </div>
    """
  end

  def select(assigns) do
    assigns = normalize(assigns)

    assigns =
      assign(
        assigns,
        :search?,
        (assigns.searchable or
           (assigns.search_threshold && length(assigns.opts) >= assigns.search_threshold)) ||
          false
      )

    if assigns.search? do
      legacy_select(assigns)
    else
      zag_select(assigns)
    end
  end

  # Zag-driven rich select. Same public attrs and `lui-*` styling as the
  # legacy path; internal markup follows the Zag select anatomy
  # (`data-scope="select"` + `data-part`) so `connect()` can spread machine
  # props onto it. The trigger keeps the stable `@id` (via the machine
  # `ids` override) so `<label for>` keeps working; every other part id is
  # Zag-generated, except items, which render deterministic ids
  # (`select:<hook>:option:<value>`) so morphs match them across
  # option-list patches. Zag-written attributes are shielded from morphs by
  # `phx-mounted` + `JS.ignore_attributes` on the hook root (one rule, all
  # parts — LiveView resolves `:to` with `querySelectorAll`).
  defp zag_select(assigns) do
    hook_id = "#{assigns.id}-select"

    assigns =
      assigns
      |> assign(:hook_id, hook_id)
      |> assign(:items_json, Jason.encode!(zag_items(assigns.opts)))
      |> assign(
        :value_json,
        Jason.encode!(if assigns.controlled, do: assigns.values_s, else: [])
      )
      |> assign(:default_json, Jason.encode!(assigns.values_s))

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div
        id={@hook_id}
        class="lui-select"
        phx-hook="LanternSelect"
        phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"select\"]")}
        data-zag
        data-items={@items_json}
        data-controlled={@controlled || nil}
        data-value={if @controlled, do: @value_json}
        data-default-value={unless @controlled, do: @default_json}
        data-trigger-id={@id}
        data-labelled-by={@id}
        data-placeholder={@placeholder}
        data-invalid={@errors != [] || nil}
        data-multiple={@multiple || nil}
        data-max={@max}
        data-name={@name}
        data-on-change={@on_change}
        data-on-change-client={@on_change_client}
      >
        <div data-scope="select" data-part="root">
          <select
            :if={@include_hidden}
            class="lui-sr-only"
            data-scope="select"
            data-part="hidden-select"
            name={(@multiple && "#{@name}[]") || @name}
            multiple={@multiple}
            disabled={@disabled}
            aria-hidden="true"
            tabindex="-1"
            {hidden_rest(@rest)}
          >
            <option :if={!@multiple} value="" selected={@values_s == []}>{@prompt}</option>
            <option
              :for={{label, value} <- @opts}
              value={value}
              selected={to_string(value) in @values_s}
            >
              {label}
            </option>
          </select>
          <div data-scope="select" data-part="control">
            <button
              type="button"
              id={@id}
              class="lui-select-toggle"
              data-scope="select"
              data-part="trigger"
              disabled={@disabled}
              aria-haspopup="listbox"
              aria-expanded="false"
              aria-describedby={@errors != [] && "#{@id}-error"}
            >
              <span
                class="lui-select-value"
                data-scope="select"
                data-part="item-text"
                data-placeholder={@placeholder}
                data-empty={toggle_label(@opts, @values_s, @multiple) == nil || nil}
              >
                {toggle_label(@opts, @values_s, @multiple) || @placeholder}
              </span>
              <Icon.icon name="chevron-up-down" class="lui-select-caret" />
            </button>
          </div>
          <button
            :if={@clearable && @values_s != []}
            type="button"
            class="lui-select-clear"
            data-scope="select"
            data-part="clear-trigger"
            aria-label="Clear selection"
            tabindex="-1"
          >
            <Icon.icon name="x-mark" />
          </button>

          <div data-scope="select" data-part="positioner" popover="manual">
            <div
              class="lui-select-listbox"
              data-scope="select"
              data-part="content"
              role="listbox"
              aria-multiselectable={@multiple && "true"}
              aria-labelledby={@id}
              hidden
              tabindex="-1"
            >
              <div class="lui-select-options">
                <button
                  :for={{label, value} <- @opts}
                  type="button"
                  id={zag_item_id(@hook_id, value)}
                  class="lui-select-option"
                  role="option"
                  data-scope="select"
                  data-part="item"
                  data-value={value}
                  aria-selected={to_string(to_string(value) in @values_s)}
                  tabindex="-1"
                >
                  <span
                    class="lui-select-option-label"
                    data-scope="select"
                    data-part="item-text"
                  >
                    {label}
                  </span>
                  <span data-scope="select" data-part="item-indicator" class="lui-select-check">
                    <Icon.icon name="check" />
                  </span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
      <p :if={@help_text && @errors == []} class="lui-help">{@help_text}</p>
    </div>
    """
  end

  # Attributes Zag writes after mount. LiveView must not clobber them on
  # patches — the machine is the writer, the server copy is stale by design.
  # Deliberately NOT ignored: `value`/`selected` (hidden-option form state),
  # `aria-describedby` (server-owned error wiring), and trigger text content
  # (re-asserted from machine state in `update()` instead).
  defp zag_ignored_attrs do
    ~w(
      data-state data-orientation dir id data-disabled data-readonly
      data-invalid data-required data-open data-focus data-focus-visible
      data-active data-hover data-placement data-highlighted data-value
      aria-expanded aria-controls aria-haspopup aria-labelledby aria-label
      aria-selected aria-checked aria-disabled aria-multiselectable
      disabled hidden role tabindex style
    )
  end

  defp zag_items(opts) do
    Enum.map(opts, fn {label, value} -> %{value: to_string(value), label: label} end)
  end

  # Mirrors the Zag default item id (`select:<machine>:option:<value>`) so
  # server and client agree and morphs match items across patches. The
  # machine id is the hook root id.
  defp zag_item_id(hook_id, value), do: "select:#{hook_id}:option:#{value}"

  defp legacy_select(assigns) do
    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div
        id={"#{@id}-select"}
        class="lui-select"
        phx-hook="LanternSelect"
        data-invalid={@errors != [] || nil}
        data-multiple={@multiple || nil}
        data-max={@max}
        data-name={@name}
        data-no-results={@search_no_results_text}
      >
        <select
          :if={@include_hidden}
          class="lui-sr-only"
          data-part="native"
          name={(@multiple && "#{@name}[]") || @name}
          multiple={@multiple}
          disabled={@disabled}
          aria-hidden="true"
          tabindex="-1"
          {hidden_rest(@rest)}
        >
          <option :if={!@multiple} value="" selected={@values_s == []}>{@prompt}</option>
          <option
            :for={{label, value} <- @opts}
            value={value}
            selected={to_string(value) in @values_s}
          >
            {label}
          </option>
        </select>
        <button
          type="button"
          id={@id}
          class="lui-select-toggle"
          data-part="toggle"
          disabled={@disabled}
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-describedby={@errors != [] && "#{@id}-error"}
        >
          <span
            class="lui-select-value"
            data-part="label"
            data-placeholder={@placeholder}
            data-empty={toggle_label(@opts, @values_s, @multiple) == nil || nil}
          >
            {toggle_label(@opts, @values_s, @multiple) || @placeholder}
          </span>
          <Icon.icon name="chevron-up-down" class="lui-select-caret" />
        </button>
        <button
          :if={@clearable && @values_s != []}
          type="button"
          class="lui-select-clear"
          data-part="clear"
          aria-label="Clear selection"
          tabindex="-1"
        >
          <Icon.icon name="x-mark" />
        </button>

        <div
          class="lui-select-listbox"
          data-part="panel"
          popover="manual"
          role="listbox"
          aria-multiselectable={@multiple && "true"}
          hidden
          tabindex="-1"
        >
          <div :if={@search?} class="lui-select-search">
            <Icon.icon name="magnifying-glass" />
            <input
              type="text"
              data-part="search-input"
              placeholder={@search_input_placeholder}
              aria-label={@search_input_placeholder}
              autocomplete="off"
            />
          </div>
          <div class="lui-select-options" data-part="options">
            <button
              :for={{label, value} <- @opts}
              type="button"
              class="lui-select-option"
              role="option"
              data-part="option"
              data-value={value}
              aria-selected={to_string(to_string(value) in @values_s)}
              tabindex="-1"
            >
              <span class="lui-select-option-label">{label}</span>
              <Icon.icon name="check" class="lui-select-check" />
            </button>
          </div>
          <p class="lui-select-noresults" data-part="no-results" hidden>{@search_no_results_text}</p>
        </div>
      </div>

      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
      <p :if={@help_text && @errors == []} class="lui-help">{@help_text}</p>
    </div>
    """
  end

  defp normalize(assigns) do
    values_s =
      assigns.value
      |> List.wrap()
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&to_string/1)

    assigns
    |> assign(:opts, Enum.map(assigns.options, &option_pair/1))
    |> assign(:value_s, List.first(values_s))
    |> assign(:values_s, values_s)
    |> assign(:id, assigns.id || default_id(assigns))
  end

  # Id fallback when neither `id` nor `field` is given (a bare `name=`). An
  # explicit `id` always wins, and the `field` clause has already resolved
  # `field.id` before we get here — so this only decides the ad-hoc path, where
  # `name` alone is NOT form-scoped and therefore not unique by construction.
  #
  # The two paths pull opposite ways, so they resolve differently:
  #
  #   * rich path — `@id` is the `phx-hook="LanternSelect"` element's id
  #     (`#{@id}-select`) and JS targets it, so it MUST stay stable across
  #     patches. Uniqueness loses; derive from `name` (matches Fluxon).
  #   * native path — a plain `<select>` with no hook; `@id` only wires
  #     `<label for>` and `#{@id}-error`. Nothing needs it stable, so
  #     uniqueness wins and we generate (matches Fluxon's `gen_id()`).
  #
  # A stateless function component cannot be told which instance it is, so a
  # bare `name` cannot be both unique and stable. Callers who need a stable id
  # on the native path pass one explicitly.
  defp default_id(%{native: true}), do: "lui-select-#{System.unique_integer([:positive])}"
  defp default_id(%{name: name}), do: name

  defp toggle_label(opts, values_s, multiple) do
    case {multiple, values_s} do
      {_, []} -> nil
      {false, [v | _]} -> selected_label(opts, v)
      {true, [v]} -> selected_label(opts, v)
      {true, vs} -> "#{length(vs)} selected"
    end
  end

  defp option_pair(%{label: label, value: value}), do: {label, value}
  defp option_pair({label, value}), do: {label, value}
  defp option_pair(value), do: {to_string(value), value}

  defp selected_label(_opts, nil), do: nil
  defp selected_label(_opts, ""), do: nil

  defp selected_label(opts, value_s) do
    Enum.find_value(opts, fn {label, value} -> to_string(value) == value_s && label end)
  end

  # `form=` must ride on the hidden input (out-of-form usage); phx-* stay on it
  # too so a change event reaches the LiveView.
  defp hidden_rest(rest), do: Map.take(rest, [:form, :"phx-change", :"phx-target"])
end
