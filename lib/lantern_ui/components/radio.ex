defmodule LanternUI.Components.Radio do
  @moduledoc """
  Radio group for exclusive single selection. Mirrors Fluxon's `radio_group/1`
  as `radio/1` so templates call `<.radio>`.

      <.radio name="plan" value={@plan} label="Plan">
        <:radio value="basic" label="Basic" />
        <:radio value="pro" label="Pro" sublabel="Popular" />
      </.radio>

      <.radio field={@form[:tier]} variant="cards" label="Tier">
        <:radio value="free" label="Free" description="Hobby projects" />
        <:radio value="team" label="Team" description="Collaboration" />
      </.radio>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias Phoenix.LiveView.JS

  attr(:id, :any, default: nil, doc: "Element id; derived from field or name when omitted.")
  attr(:name, :string, default: nil, doc: "Shared radio name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Currently selected option value.")
  attr(:label, :string, default: nil, doc: "Group label above the options.")
  attr(:sublabel, :string, default: nil, doc: "Secondary line under the group label.")
  attr(:description, :string, default: nil, doc: "Helper text under the group label.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")

  attr(:variant, :string,
    default: "list",
    values: ~w(list cards),
    doc: "list is compact radios; cards is selectable panels."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:controlled, :boolean,
    default: false,
    doc: "Server-driven value: `value` is truth, patches flow into the machine."
  )

  attr(:on_change, :string,
    default: nil,
    doc: "Server event pushed on pick (`lantern:radio:set-value` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on pick."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :radio, required: true, doc: "One exclusive option in the group." do
    attr(:value, :any, required: true, doc: "Option value submitted when selected.")
    attr(:label, :string, doc: "Primary label for this option.")
    attr(:sublabel, :string, doc: "Secondary label for this option.")
    attr(:description, :string, doc: "Helper text under this option's labels.")
    attr(:disabled, :boolean, doc: "Disable this option only.")
  end

  def radio(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> radio()
  end

  def radio(assigns) do
    assigns =
      assigns
      |> assign(:invalid?, assigns.errors != [])
      |> assign(
        :id,
        assigns.id || assigns.name || "lui-radio-#{System.unique_integer([:positive])}"
      )

    ~H"""
    <fieldset
      id={@id}
      class={Class.merge(["lui-radio-group", @class])}
      data-scope="radio-group"
      data-part="root"
      data-variant={@variant}
      data-disabled={@disabled || nil}
      data-invalid={@invalid? || nil}
      phx-hook="LanternRadio"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"radio-group\"]")}
      data-zag
      data-name={@name}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: to_string(@value || "")}
      data-default-value={unless @controlled, do: to_string(@value || "")}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      {@rest}
    >
      <legend :if={@label} class="lui-radio-legend">
        {@label}
        <span :if={@sublabel} class="lui-sublabel">{@sublabel}</span>
      </legend>
      <p :if={@description} class="lui-description">{@description}</p>

      <label
        :for={{opt, index} <- Enum.with_index(@radio)}
        class="lui-radio"
        data-scope="radio-group"
        data-part="item"
        data-value={to_string(opt[:value])}
        data-disabled-item={@disabled || opt[:disabled] || nil}
        data-disabled={@disabled || opt[:disabled] || nil}
      >
        <input
          type="radio"
          id={@id && "#{@id}-#{index}"}
          name={@name}
          value={to_string(opt[:value])}
          checked={to_string(opt[:value]) == to_string(@value)}
          disabled={@disabled || opt[:disabled]}
          class="lui-radio-input"
          aria-invalid={@invalid? && "true"}
        />
        <span
          class="lui-radio-dot"
          data-scope="radio-group"
          data-part="item-control"
          aria-hidden="true"
        ></span>
        <span :if={opt[:label]} class="lui-radio-texts">
          <span class="lui-radio-label">
            {opt[:label]}
            <span :if={opt[:sublabel]} class="lui-sublabel">{opt[:sublabel]}</span>
          </span>
          <span :if={opt[:description]} class="lui-radio-desc">{opt[:description]}</span>
        </span>
        <span :if={opt[:inner_block]} class="contents">{render_slot(opt)}</span>
      </label>

      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </fieldset>
    """
  end

  # Attributes Zag writes after mount. LiveView must not clobber them on
  # patches — the machine is the writer, the server copy is stale by design.
  # Same list as the select prototype's `zag_ignored_attrs/0`. Deliberately
  # NOT ignored: `checked` on the native inputs (form state, re-asserted
  # from machine state in `update()` instead).
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
