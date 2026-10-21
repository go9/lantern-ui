defmodule LanternUI.Components.SplitPane do
  @moduledoc """
  Two resizable columns for list/detail pages and main/cockpit layouts.

  `size`, `min` and `max` are percentages of the available column space,
  measured from inline-start. Width is remembered only when `storage_key` is set;
  scope that key to the signed-in user/project. The hook owns the resized style
  and separator value after mount; the server owns `mobile_pane`.

  Below 48rem only `mobile_pane` is displayed. Put selection/Back controls in
  your content and update this attr in LiveView; drawer/collapse policy belongs
  to the host. Slots remain mounted, so drafts survive switching panes.

      <.split_pane id="reports" label="Reports list width" storage_key="reports">
        <:primary>Report list</:primary>
        <:secondary>Selected report</:secondary>
      </.split_pane>

  Keyboard: Left/Right resize by 1%, Shift by 10%; Home/End reach the bounds.
  Inline direction is respected. There is no animation, including under reduced
  motion. Without JavaScript the initial columns and mobile selection still work.
  """
  use Phoenix.Component
  alias LanternUI.Class
  alias Phoenix.LiveView.JS

  attr(:id, :string,
    required: true,
    doc: "Stable root id; pane and separator ids derive from it."
  )

  attr(:label, :string, required: true, doc: "Accessible name of the resize separator.")
  attr(:size, :integer, default: 35, doc: "Initial primary width as a percentage.")
  attr(:min, :integer, default: 20, doc: "Minimum primary percentage, greater than zero.")
  attr(:max, :integer, default: 80, doc: "Maximum primary percentage, less than 100.")
  attr(:storage_key, :string, default: nil, doc: "Opt-in localStorage key suffix.")

  attr(:mobile_pane, :string,
    values: ~w(primary secondary),
    default: "primary",
    doc: "Server-selected visible pane below 48rem."
  )

  attr(:class, :any, default: nil, doc: "Extra root classes.")
  attr(:rest, :global, doc: "Global attributes passed to the root.")
  slot(:primary, required: true, doc: "Inline-start content, whose width the separator controls.")
  slot(:secondary, required: true, doc: "Content filling the remaining column space.")

  @doc "Render a horizontal split with a keyboard and pointer resize separator."
  def split_pane(assigns) do
    unless 0 < assigns.min and assigns.min <= assigns.size and assigns.size <= assigns.max and
             assigns.max < 100 do
      raise ArgumentError, "split_pane requires 0 < min <= size <= max < 100"
    end

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-split-pane", @class])}
      phx-hook="LanternSplitPane"
      data-size={@size}
      data-min={@min}
      data-max={@max}
      data-storage-key={@storage_key}
      data-mobile-pane={@mobile_pane}
      {@rest}
    >
      <div
        id={"#{@id}-primary"}
        class="lui-split-pane-primary"
        data-part="primary"
        style={"--lantern-split-size: #{@size / 100}"}
        phx-mounted={JS.ignore_attributes("style")}
      >
        {render_slot(@primary)}
      </div>
      <div
        id={"#{@id}-separator"}
        class="lui-split-pane-separator"
        data-part="separator"
        role="separator"
        tabindex="0"
        aria-label={@label}
        aria-orientation="vertical"
        aria-controls={"#{@id}-primary"}
        aria-valuemin={@min}
        aria-valuemax={@max}
        aria-valuenow={@size}
        phx-mounted={JS.ignore_attributes("aria-valuenow")}
      >
      </div>
      <div id={"#{@id}-secondary"} class="lui-split-pane-secondary" data-part="secondary">
        {render_slot(@secondary)}
      </div>
    </div>
    """
  end
end
