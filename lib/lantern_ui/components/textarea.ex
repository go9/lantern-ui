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

  attr(:id, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:rows, :integer, default: 4)
  attr(:size, :string, default: "md", values: @sizes)
  attr(:class, :any, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)

  attr(:rest, :global,
    include: ~w(placeholder autocomplete autofocus readonly required minlength maxlength
                form wrap spellcheck cols phx-change phx-blur phx-focus phx-target)
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
