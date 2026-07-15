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
      |> assign(:id, assigns.id || assigns.name)

    ~H"""
    <fieldset
      class={Class.merge(["lui-radio-group", @class])}
      data-variant={@variant}
      data-disabled={@disabled || nil}
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
        <span class="lui-radio-dot" aria-hidden="true"></span>
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
end
