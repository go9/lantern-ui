defmodule LanternUI.Components.Textarea do
  @moduledoc """
  Multi-line text input. Mirrors Fluxon's `textarea/1` and matches `Form.input`
  chrome (label, description, help, errors).

      <.textarea field={@form[:bio]} label="Bio" help_text="A short intro." rows={5} />
      <.textarea name="notes" value={@notes} label="Notes" size="lg" />
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form

  @sizes ~w(xs sm md lg xl)

  attr(:id, :any, default: nil, doc: "Element id; derived from field when omitted.")
  attr(:name, :any, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Current text content of the textarea.")
  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label line under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")

  attr(:help_text, :string,
    default: nil,
    doc: "Trailing help line under the field when no errors."
  )

  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")
  attr(:rows, :integer, default: 4, doc: "Visible row count for the textarea.")
  attr(:size, :string, default: "md", values: @sizes, doc: "Control density / type scale.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:rest, :global,
    include: ~w(placeholder autocomplete autofocus readonly required minlength maxlength
                form wrap spellcheck cols phx-change phx-blur phx-focus phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  def textarea(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> textarea()
  end

  def textarea(assigns) do
    assigns = assign(assigns, :invalid?, assigns.errors != [])

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <textarea
        id={@id}
        name={@name}
        rows={@rows}
        disabled={@disabled}
        class="lui-textarea"
        data-invalid={@invalid? || nil}
        aria-invalid={@invalid? && "true"}
        aria-describedby={@invalid? && @id && "#{@id}-error"}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>

      <p :if={@help_text && !@invalid?} class="lui-help">{@help_text}</p>
      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end
end
