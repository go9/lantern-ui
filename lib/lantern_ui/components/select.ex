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

  v1 scope: single-select. Fluxon's `searchable`/`multiple`/`max` attrs are
  accepted for API compatibility but not yet implemented (compile-time
  warning-free swaps; those call sites keep Fluxon until v2).
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
  # Accepted for Fluxon API compatibility; not implemented in v1.
  attr(:searchable, :boolean, default: false)
  attr(:multiple, :boolean, default: false)
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

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div
        id={"#{@id}-select"}
        class="lui-select"
        phx-hook="LanternSelect"
        data-invalid={@errors != [] || nil}
      >
        <input
          :if={@include_hidden}
          type="hidden"
          name={@name}
          value={@value_s}
          data-part="value"
          {hidden_rest(@rest)}
        />
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
            data-empty={is_nil(selected_label(@opts, @value_s)) || nil}
          >
            {selected_label(@opts, @value_s) || @placeholder}
          </span>
          <Icon.icon name="chevron-up-down" class="lui-select-caret" />
        </button>

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
        </div>
      </div>

      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
      <p :if={@help_text && @errors == []} class="lui-help">{@help_text}</p>
    </div>
    """
  end

  defp normalize(assigns) do
    assigns
    |> assign(:opts, Enum.map(assigns.options, &option_pair/1))
    |> assign(:value_s, assigns.value && to_string(assigns.value))
    |> assign_new(:id, fn -> assigns.name end)
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
