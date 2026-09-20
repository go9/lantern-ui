defmodule LanternUI.Components.ProgressRing do
  @moduledoc """
  Deprecated alias of `LanternUI.Components.Progress.progress/1` with
  `shape="ring"`. Removed in 0.9.0.

      <.progress shape="ring" value={7} max={19} label="Completion">7 / 19</.progress>
  """
  use Phoenix.Component

  alias LanternUI.Components.Progress
  alias LanternUI.Deprecated

  attr(:value, :integer, default: nil, doc: "Completed amount. Ignored when `scope` is set.")

  attr(:max, :integer,
    default: nil,
    doc: "Total amount. Defaults to 100 when only `value` is set."
  )

  attr(:completed, :integer,
    default: nil,
    doc: "Flicker alias of `value`; used with `scope`."
  )

  attr(:scope, :integer, default: nil, doc: "Flicker alias of `max`.")

  attr(:size, :string, default: "md", values: ~w(sm md), doc: "sm is 28px; md is 40px.")

  attr(:color, :string,
    default: "success",
    values: ~w(success accent primary danger warning info),
    doc: "Semantic colour of the progress stroke."
  )

  attr(:label, :string,
    default: nil,
    doc: "Accessible name. Decorative (aria-hidden) when omitted and no inner slot."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional caption beside the ring (counts, short copy).")

  @deprecated "Use progress/1 with shape=\"ring\". Removed in 0.9.0."
  def progress_ring(assigns) do
    Deprecated.warn(:progress_ring, ~s|<.progress shape="ring">|)

    ~H"""
    <Progress.progress
      :if={@inner_block != []}
      shape="ring"
      value={@value}
      max={@max}
      completed={@completed}
      scope={@scope}
      size={@size}
      color={@color}
      label={@label}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Progress.progress>
    <Progress.progress
      :if={@inner_block == []}
      shape="ring"
      value={@value}
      max={@max}
      completed={@completed}
      scope={@scope}
      size={@size}
      color={@color}
      label={@label}
      class={@class}
      {@rest}
    />
    """
  end
end
