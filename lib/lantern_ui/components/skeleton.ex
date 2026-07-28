defmodule LanternUI.Components.Skeleton do
  @moduledoc """
  Decorative, CSS-only placeholder for content that is still loading.

  The default `block` variant is full width and one line high; `text` matches a
  line of copy and `circle` is a round avatar placeholder. Use `class` or
  `style` to match the geometry of the content it replaces. The skeleton itself
  is always hidden from assistive technology. Pass `label` to opt into a single
  polite announcement: the skeleton is wrapped in a `role="status"` region with
  a visually hidden label. When rendering many skeletons, label only one
  representative skeleton so the announcement is not repeated.

      <.skeleton />
      <.skeleton variant="text" />
      <.skeleton variant="circle" style="width: 3rem; height: 3rem;" />
      <.skeleton label="Loading profile" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:variant, :string,
    default: "block",
    values: ~w(block text circle),
    doc: "Placeholder shape: generic block, text line, or circle."
  )

  attr(:label, :string,
    default: nil,
    doc: "Opt-in polite announcement: wraps the skeleton in a `role=\"status\"` region."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:style, :any, default: nil, doc: "Inline CSS for custom placeholder geometry.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def skeleton(%{label: label} = assigns) when is_binary(label) do
    ~H"""
    <div class="lui-skeleton-status" role="status">
      <span class="lui-sr-only">{@label}</span>
      <span
        class={Class.merge(["lui-skeleton", @class])}
        style={@style}
        data-variant={data_variant(@variant)}
        aria-hidden="true"
        {@rest}
      ></span>
    </div>
    """
  end

  def skeleton(assigns) do
    ~H"""
    <span
      class={Class.merge(["lui-skeleton", @class])}
      style={@style}
      data-variant={data_variant(@variant)}
      aria-hidden="true"
      {@rest}
    ></span>
    """
  end

  # The default variant needs no data attribute (no CSS targets it), which
  # keeps bare `<.skeleton />` output identical to v1.
  defp data_variant("block"), do: nil
  defp data_variant(variant), do: variant
end
