defmodule LanternUI.Components.HostBadge do
  @moduledoc """
  Noninteractive host identity, built on `badge/1`.

      <.host_badge host="Flicker" />
      <.host_badge host="Fly" coming_soon />
      <.host_badge host="Neon" coming_soon />

  Use in resource tables, under a resource title, or beside a host radio choice.
  `coming_soon` adds visible “Coming soon” text, muted styling, and
  `aria-disabled="true"`. It never renders a link or an activator. In a picker,
  also disable the actual radio; this badge does not manage selection.

  Plain text supplies the accessible content. There is no live region, hook,
  animation, or tab stop, including under reduced motion. Host availability is
  caller-owned; names are not restricted to a provider catalog.
  """
  use Phoenix.Component

  alias LanternUI.Class
  import LanternUI.Components.Badge, only: [badge: 1]

  attr(:host, :string, required: true, doc: "Host display name.")
  attr(:coming_soon, :boolean, default: false, doc: "Unavailable host; adds Coming soon text.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the badge.")
  attr(:rest, :global, doc: "HTML attributes passed through to the noninteractive span.")

  def host_badge(assigns) do
    ~H"""
    <.badge
      size="sm"
      class={Class.merge(["lui-host-badge", @class])}
      data-coming-soon={to_string(@coming_soon)}
      aria-disabled={if @coming_soon, do: "true"}
      {@rest}
    >
      {@host}<span :if={@coming_soon}> · Coming soon</span>
    </.badge>
    """
  end
end
