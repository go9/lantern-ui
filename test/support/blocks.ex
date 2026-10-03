defmodule LanternUI.Blocks do
  @moduledoc false
  use Phoenix.Component
  # `app_shell/1` is this module's own embedded template below, so drop the
  # Layout import and call it fully qualified inside that template. Hosts with
  # plain `use LanternUI` write `<.app_shell>` (see docs/recipes.md).
  use LanternUI, except: [app_shell: 1]

  @names ~w(
    app_shell
    dashboard
    index
    detail
    settings
    form
    login
    destructive
  )a

  embed_templates("blocks/*")

  def names, do: @names

  def fixture_assigns do
    %{
      shell_crumbs: [
        %{label: "Acme", path: "/"},
        %{label: "Tickets", path: nil}
      ],
      detail_crumbs: [
        %{label: "Tickets", path: "/tickets"},
        %{label: "#241", path: nil}
      ],
      form_crumbs: [
        %{label: "Tickets", path: "/tickets"},
        %{label: "New", path: nil}
      ],
      panel_open: true,
      ticket: %{
        title: "Visible progress ring",
        identifier: "#241",
        body: "Extract the ring from flicker so 7/19 stays visible on the hub.",
        status: :in_progress,
        priority: :high,
        tag: "ui",
        completed: 7,
        scope: 19
      },
      tickets: [
        %{
          id: 241,
          title: "Visible progress ring",
          identifier: "#241",
          parent: "Dense primitives",
          href: "/tickets/241",
          status: :in_progress,
          tag: "ui",
          date: "Sep 3",
          selected: true
        },
        %{
          id: 240,
          title: "Extract eight primitives",
          identifier: "#240",
          parent: nil,
          href: "/tickets/240",
          status: :todo,
          tag: "hex",
          date: "Sep 2",
          selected: false
        },
        %{
          id: 239,
          title: "Hub dashboard grouping",
          identifier: "#239",
          parent: nil,
          href: "/tickets/239",
          status: :done,
          tag: "ui",
          date: "Aug 28",
          selected: false
        }
      ],
      meta: %{params: %{}, current_page: 2, total_pages: 3, page_size: 10, total_count: 24},
      stats: [
        %{label: "Open tickets", value: "128", subtitle: "+12 this week"},
        %{label: "In progress", value: "34", subtitle: "8 owners"},
        %{label: "Merged today", value: "19", subtitle: "across 4 repos"},
        %{label: "P95 review lag", value: "3.2h", subtitle: "-0.4h vs last week"}
      ],
      series: [
        %{date: "2026-09-20", value: 4},
        %{date: "2026-09-21", value: 7},
        %{date: "2026-09-22", value: 5},
        %{date: "2026-09-23", value: 9},
        %{date: "2026-09-24", value: 12},
        %{date: "2026-09-25", value: 8},
        %{date: "2026-09-26", value: 11},
        %{date: "2026-09-27", value: 14},
        %{date: "2026-09-28", value: 10},
        %{date: "2026-09-29", value: 13},
        %{date: "2026-09-30", value: 16},
        %{date: "2026-10-01", value: 12},
        %{date: "2026-10-02", value: 15},
        %{date: "2026-10-03", value: 19}
      ],
      activity: [
        %{
          identifier: "#241",
          title: "Visible progress ring",
          href: "/tickets/241",
          status: :in_progress,
          date: "2h ago"
        },
        %{
          identifier: "#240",
          title: "Extract eight primitives",
          href: "/tickets/240",
          status: :todo,
          date: "5h ago"
        },
        %{
          identifier: "#239",
          title: "Hub dashboard grouping",
          href: "/tickets/239",
          status: :done,
          date: "1d ago"
        }
      ]
    }
  end
end
