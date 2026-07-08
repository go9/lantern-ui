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
    ],
    "folder" => [
      "M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z"
    ],
    "folder-open" => [
      "M3.75 9.776c.112-.017.227-.026.344-.026h15.812c.117 0 .232.009.344.026m-16.5 0a2.25 2.25 0 0 0-1.883 2.542l.857 6a2.25 2.25 0 0 0 2.227 1.932H19.05a2.25 2.25 0 0 0 2.227-1.932l.857-6a2.25 2.25 0 0 0-1.883-2.542m-16.5 0V6A2.25 2.25 0 0 1 6 3.75h3.879a1.5 1.5 0 0 1 1.06.44l2.122 2.12a1.5 1.5 0 0 0 1.06.44H18A2.25 2.25 0 0 1 20.25 9v.776"
    ],
    "document" => [
      "M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
    ],
    "arrow-up-tray" => [
      "M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5m-13.5-9L12 3m0 0 4.5 4.5M12 3v13.5"
    ],
    "arrow-down-tray" => [
      "M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3"
    ],
    "arrow-path" => [
      "M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
    ],
    "trash" => [
      "m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"
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
