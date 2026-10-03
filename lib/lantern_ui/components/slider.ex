defmodule LanternUI.Components.Slider do
  @moduledoc """
  Slider — a single-thumb range input built on the WAI-ARIA APG slider pattern.
  No Fluxon equivalent; the form surface (`field`/`name`/`value`, label stack,
  errors) mirrors LanternUI's other form controls.

      <.slider field={@form[:volume]} label="Volume" />
      <.slider name="quality" value={80} min={0} max={100} step={5} label="Quality" value_text="{value}%" />

  The value lives in a hidden input (the real form control), so `phx-change`
  and form submits see it exactly like a native input. The slider is Zag-driven
  (a `@zag-js/slider` state machine, loaded on demand): the hook root carries
  `data-zag` plus `data-scope="slider"` / `data-part` anatomy, and Zag owns
  the value, pointer drag, and keyboard stepping while the hidden input stays
  the form surface. Drag moves update visuals only and the release commits
  (hidden input + `input`/`change`); keyboard steps commit immediately.
  Styling stays `lui-*` tokens. Two modes:

    * client (default) — Zag owns the value from the initial `value`.
    * server-driven (`controlled`) — the server value (`value`) is truth;
      commits flow out through `on_change`, patches flow in.

  `value_text` is a template for `aria-valuetext` — `{value}` is replaced with
  the current value (server-side on render, client-side as the hook moves the
  thumb). Give the slider a `label`; without one the accessible name falls
  back to the input `name`.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form
  alias Phoenix.LiveView.JS

  attr(:id, :any,
    default: nil,
    doc: """
    Element id. Derived from `field` when omitted; with a bare `name` it falls
    back to `name` (the id feeds the hook, so it must stay stable — never
    auto-generated).
    """
  )

  attr(:name, :string, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Current value; clamped to min..max, defaults to min.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:min, :any, default: 0, doc: "Minimum value.")
  attr(:max, :any, default: 100, doc: "Maximum value.")
  attr(:step, :any, default: 1, doc: "Step increment; PageUp/PageDown jump 10 steps.")

  attr(:value_text, :string,
    default: nil,
    doc: ~s(Template for `aria-valuetext`; `{value}` interpolates, e.g. "{value}%".)
  )

  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label line under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")
  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Field density / type scale."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:controlled, :boolean,
    default: false,
    doc: "Server-driven value: `value` is truth, patches flow into the machine."
  )

  attr(:on_change, :string,
    default: nil,
    doc: "Server event pushed on commit (`lantern:slider:set-value` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on commit."
  )

  attr(:rest, :global,
    include: ~w(form phx-change phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through (ride on the hidden input)."
  )

  def slider(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> slider()
  end

  def slider(assigns) do
    min = to_number(assigns.min, 0)
    max = to_number(assigns.max, 100)
    value = assigns.value |> to_number(min) |> clamp(min, max)
    pct = if max == min, do: 0, else: (value - min) / (max - min) * 100

    assigns =
      assigns
      |> assign(:id, assigns.id || assigns.name)
      |> assign(:invalid?, assigns.errors != [])
      |> assign(:value_n, value)
      |> assign(:pct, pct)

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} id={"#{@id}-label"} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>
      <div
        id={"#{@id}-slider"}
        class="lui-slider"
        phx-hook="LanternSlider"
        phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"slider\"]")}
        data-zag
        data-scope="slider"
        data-part="root"
        data-min={@min}
        data-max={@max}
        data-step={@step}
        data-value-text={@value_text}
        data-controlled={@controlled || nil}
        data-value={if @controlled, do: @value_n}
        data-default-value={unless @controlled, do: @value_n}
        data-disabled={@disabled || nil}
        data-invalid={@invalid? || nil}
        data-on-change={@on_change}
        data-on-change-client={@on_change_client}
        style={"--lui-slider-pct: #{@pct}%"}
      >
        <input
          type="hidden"
          data-part="input"
          id={@id}
          name={@name}
          value={@value_n}
          disabled={@disabled}
          {@rest}
        />
        <div
          class="lui-slider-track"
          data-scope="slider"
          data-part="control"
        >
          <div
            class="lui-slider-range"
            data-scope="slider"
            data-part="range"
          >
          </div>
          <span
            class="lui-slider-thumb"
            data-scope="slider"
            data-part="thumb"
            role="slider"
            tabindex={(@disabled && "-1") || "0"}
            aria-valuemin={@min}
            aria-valuemax={@max}
            aria-valuenow={@value_n}
            aria-valuetext={
              @value_text && String.replace(@value_text, "{value}", to_string(@value_n))
            }
            aria-labelledby={@label && "#{@id}-label"}
            aria-label={is_nil(@label) && @name}
            aria-disabled={@disabled && "true"}
            aria-invalid={@invalid? && "true"}
            aria-describedby={@invalid? && "#{@id}-error"}
          ></span>
        </div>
      </div>
      <Form.error :for={msg <- @errors} id={"#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end

  # Attributes Zag writes after mount. LiveView must not clobber them on
  # patches — the machine is the writer, the server copy is stale by design.
  # Same list as the select prototype's `zag_ignored_attrs/0`. Deliberately
  # NOT ignored: `value` on the native hidden input (form state, re-asserted
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

  defp to_number(nil, fallback), do: fallback
  defp to_number(n, _fallback) when is_number(n), do: n

  defp to_number(s, fallback) when is_binary(s) do
    case Float.parse(s) do
      {f, _} -> if f == trunc(f), do: trunc(f), else: f
      :error -> fallback
    end
  end

  defp to_number(_, fallback), do: fallback

  defp clamp(v, min, max), do: v |> Kernel.max(min) |> Kernel.min(max)
end
