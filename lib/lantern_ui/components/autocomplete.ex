defmodule LanternUI.Components.Autocomplete do
  @moduledoc """
  A Fluxon-compatible autocomplete for static or LiveView-backed search.

      <.autocomplete field={@form[:sku]} options={@sku_options} />
      <.autocomplete name="user_id" options={@users} on_search="search_users" />

  Static options are filtered in the browser. When `on_search` is set, the
  LiveView owns the options and receives `%{"query" => query}` after the
  configured threshold and debounce.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias LanternUI.Components.Icon

  attr(:id, :any, default: nil, doc: "Element id; derived from field when omitted.")
  attr(:name, :any, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Current selected value.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:options, :list, default: [], doc: "Choices as values, tuples, or nested labelled groups.")
  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label beside the primary label.")
  attr(:description, :string, default: nil, doc: "Description between label and control.")
  attr(:help_text, :string, default: nil, doc: "Help line shown when there are no errors.")
  attr(:placeholder, :string, default: nil, doc: "Placeholder shown in the search input.")
  attr(:autofocus, :boolean, default: false, doc: "Focus the search input on page load.")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Control density and type scale."
  )

  attr(:disabled, :boolean, default: false, doc: "Disable searching and selection.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")
  attr(:search_threshold, :integer, default: 0, doc: "Characters required before searching.")

  attr(:no_results_text, :string,
    default: ~s(No results found for "%{query}".),
    doc: "Empty copy; `%{query}` is replaced in the browser."
  )

  attr(:on_search, :string,
    default: nil,
    doc: "LiveView search event receiving `%{\"query\" => query}`."
  )

  attr(:debounce, :integer, default: 200, doc: "Server-search debounce in milliseconds.")

  attr(:search_mode, :string,
    default: "contains",
    values: ~w(contains starts-with exact),
    doc: "Static matching mode."
  )

  attr(:open_on_focus, :boolean, default: false, doc: "Open the suggestions when focused.")

  attr(:animation, :string,
    default: "transition duration-150 ease-in-out",
    doc: "Compatibility classes for panel animation."
  )

  attr(:animation_enter, :string,
    default: "opacity-100 scale-100",
    doc: "Compatibility classes for panel entry."
  )

  attr(:animation_leave, :string,
    default: "opacity-0 scale-95",
    doc: "Compatibility classes for panel exit."
  )

  attr(:clearable, :boolean, default: false, doc: "Show a button that clears the selection.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the field wrapper.")

  attr(:rest, :global,
    include: ~w(form phx-change phx-target),
    doc: "Form and LiveView attributes passed to the hidden value input."
  )

  slot(:inner_prefix, doc: "Content inside the control before the input.") do
    attr(:class, :any, doc: "Classes for the affix container.")
  end

  slot(:outer_prefix, doc: "Content outside the control before it.") do
    attr(:class, :any, doc: "Classes for the affix container.")
  end

  slot(:inner_suffix, doc: "Content inside the control after the input.") do
    attr(:class, :any, doc: "Classes for the affix container.")
  end

  slot(:outer_suffix, doc: "Content outside the control after it.") do
    attr(:class, :any, doc: "Classes for the affix container.")
  end

  slot(:option, doc: "Rich option content; receives `{label, value}`.") do
    attr(:class, :any, doc: "Classes for each rich option.")
  end

  slot(:empty_state, doc: "Custom content displayed when no result matches.") do
    attr(:class, :any, doc: "Classes for the empty-state container.")
  end

  slot(:header, doc: "Content at the top of the suggestions panel.") do
    attr(:class, :any, doc: "Classes for the header container.")
  end

  slot(:footer, doc: "Content at the bottom of the suggestions panel.") do
    attr(:class, :any, doc: "Classes for the footer container.")
  end

  def autocomplete(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> autocomplete()
  end

  def autocomplete(assigns) do
    assigns = normalize(assigns)

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div
        id={"#{@id}-ac"}
        class="lui-autocomplete"
        phx-hook="LanternAutocomplete"
        data-name={@name}
        data-server-search={@on_search}
        data-debounce={@debounce}
        data-search-threshold={@search_threshold}
        data-search-mode={@search_mode}
        data-open-on-focus={to_string(@open_on_focus)}
        data-empty-template={@no_results_text}
        data-animation-enter={@animation_enter}
        data-animation-leave={@animation_leave}
      >
        <input type="hidden" name={@name} value={@value_s} data-part="value" {hidden_rest(@rest)} />
        <div class="lui-autocomplete-row">
          <span
            :for={slot <- @outer_prefix}
            class={Class.merge(["lui-autocomplete-affix lui-autocomplete-outer", slot[:class]])}
          >
            {render_slot(slot)}
          </span>
          <div class="lui-autocomplete-control">
            <span
              :for={slot <- @inner_prefix}
              class={Class.merge(["lui-autocomplete-affix", slot[:class]])}
            >
              {render_slot(slot)}
            </span>
            <input
              type="text"
              id={@id}
              class="lui-autocomplete-input"
              data-part="input"
              placeholder={@placeholder}
              autocomplete="off"
              role="combobox"
              aria-expanded="false"
              aria-autocomplete="list"
              aria-controls={"#{@id}-listbox"}
              aria-describedby={@errors != [] && "#{@id}-error"}
              value={selected_label(@items, @value_s)}
              autofocus={@autofocus}
              disabled={@disabled}
            />
            <span
              :for={slot <- @inner_suffix}
              class={Class.merge(["lui-autocomplete-affix", slot[:class]])}
            >
              {render_slot(slot)}
            </span>
            <button
              :if={@clearable}
              type="button"
              class="lui-autocomplete-clear"
              data-part="clear"
              aria-label="Clear selection"
              hidden={is_nil(@value_s)}
              disabled={@disabled}
            >
              <Icon.icon name="x-mark" />
            </button>
            <Icon.icon name="chevron-up-down" class="lui-select-caret" />
          </div>
          <span
            :for={slot <- @outer_suffix}
            class={Class.merge(["lui-autocomplete-affix lui-autocomplete-outer", slot[:class]])}
          >
            {render_slot(slot)}
          </span>
        </div>

        <div
          id={"#{@id}-listbox"}
          class={Class.merge(["lui-select-listbox", @animation])}
          data-part="panel"
          role="listbox"
          aria-label={@label || @placeholder || "Suggestions"}
          hidden
          tabindex="-1"
        >
          <div :for={slot <- @header} class={Class.merge(["lui-autocomplete-header", slot[:class]])}>
            {render_slot(slot)}
          </div>
          <div data-part="options">
            <%= for item <- @items do %>
              <div
                :if={item.kind == :group}
                class="lui-autocomplete-group"
                data-part="group"
                data-depth={item.depth}
              >
                {item.label}
              </div>
              <button
                :if={item.kind == :option}
                id={"#{@id}-option-#{item.index}"}
                type="button"
                class={Class.merge(["lui-select-option", option_slot_class(@option)])}
                role="option"
                data-part="option"
                data-value={item.value}
                data-label={item.label}
                data-depth={item.depth}
                aria-selected={to_string(to_string(item.value) == @value_s)}
                tabindex="-1"
              >
                <span class="lui-select-option-label">
                  <%= if @option == [] do %>
                    {item.label}
                  <% else %>
                    {render_slot(@option, {item.label, item.value})}
                  <% end %>
                </span>
                <Icon.icon name="check" class="lui-select-check" />
              </button>
            <% end %>
          </div>
          <div class="lui-autocomplete-loading" data-part="loading" role="status" hidden>
            <span class="lui-autocomplete-spinner" aria-hidden="true"></span>
            <span>Loading results</span>
          </div>
          <div
            class={Class.merge(["lui-select-noresults", empty_slot_class(@empty_state)])}
            data-part="no-results"
            data-default-text={to_string(@empty_state == [])}
            hidden
          >
            <%= if @empty_state == [] do %>
              {@no_results_text}
            <% else %>
              {render_slot(@empty_state)}
            <% end %>
          </div>
          <div :for={slot <- @footer} class={Class.merge(["lui-autocomplete-footer", slot[:class]])}>
            {render_slot(slot)}
          </div>
        </div>
      </div>

      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
      <p :if={@help_text && @errors == []} class="lui-help">{@help_text}</p>
    </div>
    """
  end

  defp normalize(assigns) do
    value_s =
      assigns.value
      |> List.wrap()
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&to_string/1)
      |> List.first()

    assigns
    |> assign(:items, normalize_options(assigns.options))
    |> assign(:value_s, value_s)
    |> assign(:id, assigns.id || assigns.name)
  end

  defp normalize_options(options) do
    {items, _index} = normalize_options(options, 0, 0)
    items
  end

  defp normalize_options(options, depth, index) do
    Enum.reduce(options, {[], index}, fn
      {label, children}, {items, next} when is_list(children) ->
        group = %{kind: :group, label: label, depth: depth, index: next}
        {nested, after_nested} = normalize_options(children, depth + 1, next + 1)
        {items ++ [group | nested], after_nested}

      {label, value}, {items, next} ->
        {items ++ [%{kind: :option, label: label, value: value, depth: depth, index: next}],
         next + 1}

      value, {items, next} ->
        {items ++
           [%{kind: :option, label: to_string(value), value: value, depth: depth, index: next}],
         next + 1}
    end)
  end

  defp selected_label(_items, value_s) when value_s in [nil, ""], do: nil

  defp selected_label(items, value_s) do
    Enum.find_value(items, fn item ->
      item.kind == :option && to_string(item.value) == value_s && item.label
    end)
  end

  defp option_slot_class([]), do: nil
  defp option_slot_class([slot | _]), do: slot[:class]
  defp empty_slot_class([]), do: nil
  defp empty_slot_class([slot | _]), do: slot[:class]
  defp hidden_rest(rest), do: Map.take(rest, [:form, :"phx-change", :"phx-target"])
end
