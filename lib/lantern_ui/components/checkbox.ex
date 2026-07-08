defmodule LanternUI.Components.Checkbox do
  @moduledoc """
  Checkbox with label, description, and error states.

      <.checkbox field={@form[:accept]} label="Accept the terms" />
      <.checkbox name="notify" checked={@notify} label="Email me" description="At most one per day." />

  The API mirrors Fluxon's `checkbox/1` (`field`/`name`/`checked`,
  `checked_value`/`unchecked_value`, `label`/`sublabel`/`description`,
  `errors`), so a `use Fluxon` app can swap imports without template changes.
  A hidden input submits `unchecked_value` when the box is unchecked, so forms
  always receive the param. (`checkbox_group/1` is not yet implemented.)
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form

  attr(:id, :any, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:checked_value, :any, default: "true")
  attr(:unchecked_value, :any, default: "false")
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:class, :any, default: nil)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global)

  def checkbox(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> checkbox()
  end

  def checkbox(assigns) do
    assigns =
      assigns
      |> assign(:invalid?, assigns.errors != [])
      |> then(fn a ->
        if is_nil(a.checked),
          do: assign(a, :checked, to_string(a.value) == to_string(a.checked_value)),
          else: a
      end)

    ~H"""
    <div class={Class.merge(["lui-checkbox-field", @class])}>
      <label class="lui-checkbox-row" data-disabled={@disabled}>
        <input type="hidden" name={@name} value={to_string(@unchecked_value)} disabled={@disabled} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value={to_string(@checked_value)}
          checked={@checked}
          disabled={@disabled}
          class="lui-checkbox"
          aria-invalid={@invalid? && "true"}
          aria-describedby={@invalid? && @id && "#{@id}-error"}
          {@rest}
        />
        <span :if={@label} class="lui-checkbox-label">
          {@label}
          <span :if={@sublabel} class="lui-sublabel">{@sublabel}</span>
          <span :if={@description} class="lui-checkbox-desc">{@description}</span>
        </span>
      </label>
      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
