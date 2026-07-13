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

  `searchable` adds a search box to the listbox (client-side filtering; or set
  `search_threshold` to auto-enable at N options). `multiple` turns the picker
  into a multi-select: options toggle, the panel stays open, the toggle shows
  a count, and one hidden `name[]` input is submitted per selected value.
  Fluxon's `on_search` (server-driven options) is not yet implemented.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias LanternUI.Components.Icon

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:options, :list, default: [])
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:placeholder, :string, default: "Select…")
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:disabled, :boolean, default: false)
  attr(:errors, :list, default: [])
  attr(:native, :boolean, default: false)
  attr(:include_hidden, :boolean, default: true)
  attr(:prompt, :string, default: nil, doc: "blank first option (native path)")
  attr(:searchable, :boolean, default: false, doc: "search box inside the listbox")
  attr(:search_threshold, :integer, default: nil, doc: "auto-enable search at N+ options")
  attr(:search_input_placeholder, :string, default: "Search…")
  attr(:search_no_results_text, :string, default: "No results")
  attr(:multiple, :boolean, default: false, doc: "multi-select; submits name[] hidden inputs")
  attr(:max, :integer, default: nil, doc: "max selections when multiple")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form phx-change phx-target))

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
        <span :if={@include_hidden} data-part="values">
          <%= if @multiple do %>
            <input
              :for={v <- @values_s}
              type="hidden"
              name={"#{@name}[]"}
              value={v}
              data-part="value"
              {hidden_rest(@rest)}
            />
          <% else %>
            <input
              type="hidden"
              name={@name}
              value={@value_s}
              data-part="value"
              {hidden_rest(@rest)}
            />
          <% end %>
        </span>
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

        <div
          class="lui-select-listbox"
          data-part="panel"
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
    |> assign_new(:id, fn -> assigns.name end)
  end

  defp toggle_label(opts, values_s, multiple) do
    case {multiple, values_s} do
      {_, []} -> nil
      {false, [v | _]} -> selected_label(opts, v)
      {true, [v]} -> selected_label(opts, v)
      {true, vs} -> "#{length(vs)} selected"
    end
  end

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
