defmodule LanternUI.Components.Switch do
  @moduledoc """
  Toggle switch for binary settings. Mirrors Fluxon's `switch/1` surface.

      <.switch field={@form[:notifications]} label="Enable notifications" />
      <.switch name="dark" checked={@dark} label="Dark mode" size="sm" color="accent" />

  A hidden input always submits `unchecked_value` so forms receive a param even
  when the switch is off.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form

  attr(:id, :any, default: nil, doc: "Element id; derived from field when omitted.")
  attr(:name, :string, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Current value used to derive checked state.")

  attr(:checked, :boolean,
    default: nil,
    doc: "Force on/off; else compares value to checked_value."
  )

  attr(:checked_value, :any, default: "true", doc: "Value submitted when the switch is on.")
  attr(:unchecked_value, :any, default: "false", doc: "Hidden input value submitted when off.")
  attr(:label, :string, default: nil, doc: "Primary label text beside the switch.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label line under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")
  attr(:size, :string, default: "md", values: ~w(sm md lg), doc: "Track and thumb size.")
  attr(:color, :string, default: "accent", doc: "On-state track color token.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:rest, :global,
    include: ~w(form phx-change phx-target phx-click),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  def switch(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> switch()
  end

  def switch(assigns) do
    assigns =
      assigns
      |> assign(:invalid?, assigns.errors != [])
      |> then(fn a ->
        if is_nil(a.checked),
          do: assign(a, :checked, to_string(a.value) == to_string(a.checked_value)),
          else: a
      end)

    ~H"""
    <div class={Class.merge(["lui-switch-field", @class])}>
      <div class="lui-switch-row">
        <label
          class="lui-switch"
          data-size={@size}
          data-color={@color}
          data-disabled={@disabled || nil}
        >
          <input type="hidden" name={@name} value={to_string(@unchecked_value)} disabled={@disabled} />
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value={to_string(@checked_value)}
            checked={@checked}
            disabled={@disabled}
            class="lui-switch-input"
            aria-invalid={@invalid? && "true"}
            aria-describedby={@invalid? && @id && "#{@id}-error"}
            {@rest}
          />
          <span class="lui-switch-track" aria-hidden="true">
            <span class="lui-switch-thumb"></span>
          </span>
        </label>
        <Form.label :if={@label} for={@id} sublabel={@sublabel} class="lui-switch-label">
          {@label}
        </Form.label>
      </div>
      <p :if={@description} class="lui-description">{@description}</p>
      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end
end
