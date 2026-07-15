defmodule LanternUI.Components.Autocomplete do
  @moduledoc """
  Autocomplete - Fluxon-compatible client-side typeahead over a static options list.

      <.autocomplete field={@form[:sku]} options={@sku_options} />
      <.autocomplete name="status" value="active" options={[{"Active", "active"}]} />

  Options are strings, atoms, numbers, or `{label, value}` tuples. The visible
  input filters the listbox on the client; a hidden input carries the selected
  value for form submission.
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

  attr(:options, :list, default: [], doc: "Choices as values or {label, value} tuples.")
  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")
  attr(:help_text, :string, default: nil, doc: "Trailing help line when there are no errors.")
  attr(:placeholder, :string, default: "Search…", doc: "Placeholder shown in the text input.")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Control density / type scale."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")
  attr(:search_threshold, :integer, default: nil, doc: "Accepted for Fluxon compatibility.")

  attr(:no_results_text, :string,
    default: "No results",
    doc: "Empty-state copy when no option matches."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the field wrapper.")

  attr(:rest, :global,
    include: ~w(form phx-change phx-target),
    doc: "Form and LiveView attributes passed to the hidden value input."
  )

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
      >
        <input
          type="hidden"
          name={@name}
          value={@value_s}
          data-part="value"
          {hidden_rest(@rest)}
        />
        <div class="lui-autocomplete-control">
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
            aria-describedby={@errors != [] && "#{@id}-error"}
            value={selected_label(@opts, @value_s)}
            disabled={@disabled}
          />
          <Icon.icon name="chevron-up-down" class="lui-select-caret" />
        </div>
        <div class="lui-select-listbox" data-part="panel" role="listbox" hidden tabindex="-1">
          <button
            :for={{label, value} <- @opts}
            type="button"
            class="lui-select-option"
            role="option"
            data-part="option"
            data-value={value}
            aria-selected={to_string(to_string(value) == @value_s)}
            tabindex="-1"
          >
            <span class="lui-select-option-label">{label}</span>
            <Icon.icon name="check" class="lui-select-check" />
          </button>
          <p class="lui-select-noresults" data-part="no-results" hidden>{@no_results_text}</p>
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
    |> assign(:id, assigns.id || assigns.name)
  end

  defp option_pair({label, value}), do: {label, value}
  defp option_pair(value), do: {to_string(value), value}

  defp selected_label(_opts, nil), do: nil
  defp selected_label(_opts, ""), do: nil

  defp selected_label(opts, value_s) do
    Enum.find_value(opts, fn {label, value} -> to_string(value) == value_s && label end)
  end

  defp hidden_rest(rest), do: Map.take(rest, [:form, :"phx-change", :"phx-target"])
end
