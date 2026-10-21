defmodule LanternUI.Components.FunnelLine do
  @moduledoc """
  A compact sequence of counted filters, with optional overflow stages.

  The line is the filter: do not repeat it in a menu or add a second total.
  Callers calculate mutually exclusive bucket counts (a cluster counts once),
  own selection, and filter their list in response to `on_change` with
  `%{"value" => value}`. No bucket names or application policy are built in.

      <.funnel_line id="reports" label="Where reports are" value={@bucket} on_change="filter">
        <:stage value="needs" label="Needs you" count={7} />
        <:stage value="work" label="In work" count={2} />
        <:stage value="shipped" label="Shipped" count={1} />
        <:stage value="told" label="Told" count={1} />
        <:stage value="snoozed" label="Snoozed" count={1} overflow />
        <:stage value="held" label="Held" count={0} overflow />
      </.funnel_line>

  Primary stages remain visible at zero. Overflow stages follow a divider and
  disappear at zero, except the selected stage stays available so the reader
  can leave an emptied bucket. Ordering within each set follows slot order.

  A named `group` contains native buttons with server-owned `aria-pressed`.
  Tab/Shift+Tab traverse them; Enter/Space activate. This filters one list,
  so there are no tab panels, roving focus, or arrow-key bindings. Stable
  button ids derive from the root id and encoded stage value. Narrow layouts
  scroll horizontally; focus scrolls each button into view. No hook or motion.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.{Button, Icon}

  attr(:id, :string, required: true, doc: "Stable root id; button ids derive from stage values.")
  attr(:label, :string, required: true, doc: "Accessible name for the filter group.")
  attr(:value, :string, required: true, doc: "Selected stage value, owned by the server.")

  attr(:on_change, :any,
    required: true,
    doc: "Click event or JS command; sends params[\"value\"]."
  )

  attr(:target, :any, default: nil, doc: "Optional LiveComponent target for the click event.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the line.")
  attr(:rest, :global, doc: "HTML attributes passed through to the group.")

  slot :stage,
    required: true,
    doc: "One counted filter; primary stages precede overflow stages." do
    attr(:value, :string, required: true, doc: "Unique stable filter key.")
    attr(:label, :string, required: true, doc: "Visible stage name.")

    attr(:count, :integer,
      required: true,
      doc: "Non-negative bucket count, formatted by the component."
    )

    attr(:overflow, :boolean, doc: "Hide an empty stage unless selected; default false.")
  end

  @doc "Renders a named line of counted, server-controlled filter buttons."
  def funnel_line(assigns) do
    Enum.each(assigns.stage, fn stage ->
      unless is_integer(stage.count) and stage.count >= 0 do
        raise ArgumentError, "funnel_line stage count must be a non-negative integer"
      end
    end)

    values = Enum.map(assigns.stage, & &1.value)

    if length(values) != length(Enum.uniq(values)) do
      raise ArgumentError, "funnel_line stage values must be unique"
    end

    {overflow, primary} = Enum.split_with(assigns.stage, & &1[:overflow])

    overflow =
      Enum.filter(overflow, &(&1.count > 0 or &1.value == assigns.value))

    assigns = assign(assigns, :stages, Enum.with_index(primary ++ overflow))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-funnel-line", @class])}
      role="group"
      aria-label={@label}
      {@rest}
    >
      <span
        :for={{stage, index} <- @stages}
        class="lui-funnel-stage"
        data-overflow={to_string(!!stage[:overflow])}
      >
        <Icon.icon
          :if={index > 0 and !stage[:overflow]}
          name="chevron-right"
          class="lui-funnel-arrow"
        />
        <Button.button
          id={@id <> "-stage-" <> Base.url_encode64(stage.value, padding: false)}
          type="button"
          class="lui-funnel-button"
          size="sm"
          variant="ghost"
          pressed={stage.value == @value}
          phx-click={@on_change}
          value={stage.value}
          phx-target={@target}
        >
          {stage.label} <span class="lui-funnel-count">{stage.count}</span>
        </Button.button>
      </span>
    </div>
    """
  end
end
