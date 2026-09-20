defmodule LanternUI.Components.StateGlyph do
  @moduledoc """
  Status circles and priority signal bars for dense lists.

  Two sets, selected with `kind`. Status is Linear's circle (dotted backlog,
  empty todo, half-filled in progress, filled check for done, x for cancelled).
  Priority is Linear's signal bars, tinted by urgency; `:none` is three dashes.

      <.state_glyph kind="status" value="in_progress" />
      <.state_glyph kind="priority" value="high" size="sm" />

  Flicker-shaped aliases `status_glyph/1` and `priority_glyph/1` take
  `status=` / `priority=` so a consuming page is a rename, not a remap.
  `:selected_for_dev` draws the same empty ring as `:todo`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @status_values ~w(backlog todo selected_for_dev in_progress done cancelled)
  @priority_values ~w(urgent high medium low none)
  @sizes ~w(sm md)

  attr(:kind, :string,
    required: true,
    values: ~w(status priority),
    doc: "Glyph set: status circles or priority bars."
  )

  attr(:value, :any,
    required: true,
    doc: "Status or priority name (atom or string). See the set lists above."
  )

  attr(:size, :string, default: "md", values: @sizes, doc: "sm is 12px; md is 14px.")

  attr(:label, :string,
    default: nil,
    doc: "Accessible name. Decorative (aria-hidden) when omitted — pair with visible text."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the svg.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def state_glyph(assigns) do
    kind = kind_string(assigns.kind)
    token = token(assigns.value)

    assigns =
      assigns
      |> assign(:kind, kind)
      |> assign(:token, token)
      |> assign(:glyph, glyph(kind, token))

    ~H"""
    <svg
      class={Class.merge(["lui-state-glyph", @class])}
      viewBox="0 0 14 14"
      fill="none"
      data-kind={@kind}
      data-value={@token}
      data-size={@size}
      aria-hidden={is_nil(@label) && "true"}
      aria-label={@label}
      {@rest}
    >
      <%= case {@kind, @glyph} do %>
        <% {"status", :backlog} -> %>
          <circle
            cx="7"
            cy="7"
            r="5.5"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-dasharray="1.6 2.2"
            stroke-linecap="round"
          />
        <% {"status", :todo} -> %>
          <circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5" />
        <% {"status", :in_progress} -> %>
          <circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5" />
          <path d="M7 3.5a3.5 3.5 0 0 1 0 7z" fill="currentColor" />
        <% {"status", :done} -> %>
          <circle cx="7" cy="7" r="6.25" fill="currentColor" />
          <path
            d="M4.4 7.2l1.8 1.8 3.5-3.7"
            stroke="var(--lantern-surface, #fff)"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        <% {"status", :cancelled} -> %>
          <circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5" />
          <path
            d="M5 5l4 4M9 5l-4 4"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
          />
        <% {"priority", :urgent} -> %>
          <rect x="1" y="1" width="12" height="12" rx="2.5" fill="currentColor" />
          <path
            d="M7 3.6v4.2M7 10.2v.2"
            stroke="var(--lantern-surface, #fff)"
            stroke-width="1.6"
            stroke-linecap="round"
          />
        <% {"priority", :none} -> %>
          <path
            d="M2 7h2.5M5.75 7h2.5M9.5 7H12"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
          />
        <% {"priority", level} -> %>
          <rect x="1.5" y="8" width="2.5" height="4.5" rx="0.6" fill="currentColor" />
          <rect
            x="5.75"
            y="5"
            width="2.5"
            height="7.5"
            rx="0.6"
            fill="currentColor"
            opacity={if level in [:medium, :high], do: "1", else: "0.3"}
          />
          <rect
            x="10"
            y="1.5"
            width="2.5"
            height="11"
            rx="0.6"
            fill="currentColor"
            opacity={if level == :high, do: "1", else: "0.3"}
          />
      <% end %>
    </svg>
    """
  end

  attr(:status, :any, required: true, doc: "Workflow status (atom or string).")
  attr(:size, :string, default: "md", values: @sizes, doc: "sm is 12px; md is 14px.")
  attr(:label, :string, default: nil, doc: "Accessible name; decorative when omitted.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the svg.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  @doc "Flicker-shaped alias of `state_glyph/1` with `kind=\"status\"`."
  def status_glyph(assigns) do
    assigns
    |> assign(:kind, "status")
    |> assign(:value, assigns.status)
    |> state_glyph()
  end

  attr(:priority, :any, required: true, doc: "Priority (atom or string).")
  attr(:size, :string, default: "md", values: @sizes, doc: "sm is 12px; md is 14px.")
  attr(:label, :string, default: nil, doc: "Accessible name; decorative when omitted.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the svg.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  @doc "Flicker-shaped alias of `state_glyph/1` with `kind=\"priority\"`."
  def priority_glyph(assigns) do
    assigns
    |> assign(:kind, "priority")
    |> assign(:value, assigns.priority)
    |> state_glyph()
  end

  defp kind_string(kind) when kind in [:status, "status"], do: "status"
  defp kind_string(kind) when kind in [:priority, "priority"], do: "priority"

  defp token(value) when is_atom(value), do: Atom.to_string(value)
  defp token(value) when is_binary(value), do: value
  defp token(value), do: to_string(value)

  defp glyph("status", value) when value in @status_values do
    case value do
      "selected_for_dev" -> :todo
      other -> String.to_existing_atom(other)
    end
  end

  defp glyph("status", _), do: :todo

  defp glyph("priority", value) when value in @priority_values,
    do: String.to_existing_atom(value)

  defp glyph("priority", _), do: :none
end
