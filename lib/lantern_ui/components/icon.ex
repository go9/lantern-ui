defmodule LanternUI.Components.Icon do
  @moduledoc """
  A small, curated inline-SVG icon set (Heroicons outline paths, MIT).

  Self-contained by design: no icon font, no Tailwind plugin, no host asset
  pipeline — the SVG ships in the HTML, sized in `em` so it scales with text
  and colored via `currentColor`.

      <.icon name="chevron-down" />
      <.icon name="calendar-days" class="lui-mr-1" />

  The set is deliberately minimal: what LanternUI's own components need plus
  the everyday few. It is not a general icon system — for that, use your
  host's icon setup.
  """

  use Phoenix.Component

  # Heroicons v2 outline (24×24, stroke 1.5) path data.
  @paths %{
    "chevron-down" => ["m19.5 8.25-7.5 7.5-7.5-7.5"],
    "chevron-up" => ["m4.5 15.75 7.5-7.5 7.5 7.5"],
    "chevron-left" => ["M15.75 19.5 8.25 12l7.5-7.5"],
    "chevron-right" => ["m8.25 4.5 7.5 7.5-7.5 7.5"],
    "check" => ["m4.5 12.75 6 6 9-13.5"],
    "x-mark" => ["M6 18 18 6M6 6l12 12"],
    "plus" => ["M12 4.5v15m7.5-7.5h-15"],
    "minus" => ["M5 12h14"],
    "calendar-days" => [
      "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"
    ],
    "clock" => ["M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"],
    "magnifying-glass" => [
      "m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
    ],
    "arrow-right" => ["M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"],
    "ellipsis-horizontal" => [
      "M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z"
    ],
    "exclamation-circle" => [
      "M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z"
    ]
  }

  @names Map.keys(@paths)

  @doc """
  Renders an icon by name. Available: `#{Enum.join(@names, "`, `")}`.
  """
  attr(:name, :string, required: true, values: @names)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def icon(assigns) do
    assigns = assign(assigns, :paths, Map.fetch!(@paths, assigns.name))

    ~H"""
    <svg
      class={LanternUI.Class.merge(["lui-icon", @class])}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      {@rest}
    >
      <path :for={d <- @paths} d={d} />
    </svg>
    """
  end

  @doc false
  def names, do: @names
end
