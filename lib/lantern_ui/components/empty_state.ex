defmodule LanternUI.Components.EmptyState do
  @moduledoc """
  Quiet empty/zero state for tables, lists, and panels (a lantern-ui extension —
  Fluxon has no equivalent).

      <.empty_state icon="folder-open" title="No objects">
        Drop files here or
        <:action><.button size="sm" phx-click="upload">Upload</.button></:action>
      </.empty_state>

  Empty is not one state. Pass `kind` to say which, and give it ONE action:
  `first_use` (create), `no_match` (clear filters), `error` (retry, announced
  as an alert) or `restricted` (permission-limited, no action). Each kind
  supplies a default icon; `icon` overrides it. Keep the copy to one sentence.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:kind, :string,
    default: nil,
    values: [nil | ~w(first_use no_match error restricted)],
    doc: "Which empty state this is; sets the default icon and, for `error`, `role=alert`."
  )

  attr(:icon, :string,
    default: nil,
    doc: "Optional leading icon name (a `kind` supplies a default)."
  )

  attr(:title, :string, required: true, doc: "Primary empty-state heading.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Supporting description under the title.")
  slot(:action, doc: "CTA buttons or links below the description.")

  @kind_icons %{
    "first_use" => "inbox",
    "no_match" => "magnifying-glass",
    "error" => "exclamation-circle",
    "restricted" => "folder"
  }

  def empty_state(assigns) do
    assigns = assign(assigns, :icon, assigns.icon || @kind_icons[assigns.kind])

    ~H"""
    <div
      class={Class.merge(["lui-empty", @class])}
      data-kind={@kind}
      role={@kind == "error" && "alert"}
      {@rest}
    >
      <LanternUI.Components.Icon.icon :if={@icon} name={@icon} class="lui-empty-icon" />
      <p class="lui-empty-title">{@title}</p>
      <p :if={@inner_block != []} class="lui-empty-desc">{render_slot(@inner_block)}</p>
      <div :if={@action != []} class="lui-empty-actions">
        <span :for={a <- @action}>{render_slot(a)}</span>
      </div>
    </div>
    """
  end
end
