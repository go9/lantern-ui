defmodule LanternUI.Components.Switch do
  @moduledoc """
  Toggle switch for binary settings. Mirrors Fluxon's `switch/1` surface.

      <.switch field={@form[:notifications]} label="Enable notifications" />
      <.switch name="dark" checked={@dark} label="Dark mode" size="sm" color="accent" />

  A hidden input always submits `unchecked_value` so forms receive a param even
  when the switch is off.

  The toggle is Zag-driven (a `@zag-js/switch` state machine, loaded on
  demand): the hook root carries `data-zag` plus `data-scope="switch"` /
  `data-part` anatomy, and Zag owns checked state, keyboard, and ARIA while
  the native inputs stay the form surface. Styling stays `lui-*` tokens.
  Two modes:

    * client (default) — Zag owns the value from the initial `checked`.
    * server-driven (`controlled`) — the server value (`checked`) is truth;
      toggles flow out through `on_change`, patches flow in.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias Phoenix.LiveView.JS

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

  attr(:controlled, :boolean,
    default: false,
    doc: "Server-driven checked state: `checked` is truth, patches flow into the machine."
  )

  attr(:on_change, :string,
    default: nil,
    doc: "Server event pushed on toggle (`lantern:switch:set-checked` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on toggle."
  )

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
      |> then(fn a ->
        input_id = a.id || "lui-switch-#{System.unique_integer([:positive])}"

        assign(a,
          input_id: input_id,
          hook_id: "#{input_id}-switch",
          checked_json: Jason.encode!(!!a.checked)
        )
      end)

    ~H"""
    <div
      id={@hook_id}
      class={Class.merge(["lui-switch-field", @class])}
      phx-hook="LanternSwitch"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"switch\"]")}
      data-zag
      data-input-id={@input_id}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: @checked_json}
      data-default-value={unless @controlled, do: @checked_json}
      data-disabled={@disabled || nil}
      data-invalid={@invalid? || nil}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
    >
      <div class="lui-switch-row">
        <label
          class="lui-switch"
          data-scope="switch"
          data-part="root"
          data-size={@size}
          data-color={@color}
          data-disabled={@disabled || nil}
        >
          <input type="hidden" name={@name} value={to_string(@unchecked_value)} disabled={@disabled} />
          <input
            type="checkbox"
            id={@input_id}
            name={@name}
            value={to_string(@checked_value)}
            checked={@checked}
            disabled={@disabled}
            class="lui-switch-input"
            aria-invalid={@invalid? && "true"}
            aria-describedby={@invalid? && @input_id && "#{@input_id}-error"}
            {@rest}
          />
          <span class="lui-switch-track" data-scope="switch" data-part="control" aria-hidden="true">
            <span class="lui-switch-thumb" data-scope="switch" data-part="thumb"></span>
          </span>
        </label>
        <Form.label :if={@label} for={@input_id} sublabel={@sublabel} class="lui-switch-label">
          {@label}
        </Form.label>
      </div>
      <p :if={@description} class="lui-description">{@description}</p>
      <Form.error :for={msg <- @errors} id={@input_id && "#{@input_id}-error"}>{msg}</Form.error>
    </div>
    """
  end

  # Attributes Zag writes after mount. LiveView must not clobber them on
  # patches — the machine is the writer, the server copy is stale by design.
  # Same list as the select prototype's `zag_ignored_attrs/0`. Deliberately
  # NOT ignored: `checked` on the native input (form state, re-asserted from
  # machine state in `update()` instead).
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
end
