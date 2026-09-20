defmodule LanternUI.Recipes do
  @moduledoc false
  use Phoenix.Component
  use LanternUI

  @names ~w(
    linear_list_row
    grouped_list
    record_page
    inbox
    project_overview
    icon_toolbar
    capacity_strip
  )a

  embed_templates("recipes/*")

  def names, do: @names

  def fixture_assigns do
    %{
      ticket: %{
        title: "Visible progress ring",
        identifier: "#241",
        parent: "Dense primitives",
        href: "/tickets/241",
        status: :in_progress,
        priority: :high,
        tag: "ui",
        date: "Sep 3",
        completed: 7,
        scope: 19,
        body: "Extract the ring from flicker so 7/19 is visible."
      },
      tickets: [
        %{
          title: "Visible progress ring",
          identifier: "#241",
          parent: "Dense primitives",
          href: "/tickets/241",
          status: :in_progress,
          priority: :high,
          tag: "ui",
          date: "Sep 3",
          completed: 7,
          scope: 19,
          selected: true
        },
        %{
          title: "Extract eight primitives",
          identifier: "#240",
          parent: nil,
          href: "/tickets/240",
          status: :todo,
          priority: :medium,
          tag: "hex",
          date: "Sep 2",
          completed: 0,
          scope: 3,
          selected: false
        }
      ],
      scope: "all",
      paths: %{
        all: "/tickets",
        active: "/tickets?scope=active",
        backlog: "/tickets?scope=backlog",
        in_progress: "/tickets?status=in_progress",
        done: "/tickets?show_done=1",
        new_in_progress: "/tickets/new?status=in_progress"
      },
      panel_open: true,
      crumbs: [%{label: "Tickets", path: "/tickets"}, %{label: "#241", path: nil}],
      inbox_count: 12,
      inbox_items: [
        %{
          identifier: "#88",
          title: "Inbox three-column layout",
          href: "/inbox/88",
          kind: "bug",
          status: :todo,
          selected: true
        },
        %{
          identifier: "#87",
          title: "Snooze keeps the row",
          href: "/inbox/87",
          kind: "feature",
          status: :backlog,
          selected: false
        }
      ],
      selected: %{
        identifier: "#88",
        title: "Inbox three-column layout",
        meta: "bug · reporter · 2h",
        body: "Promote this suggestion without leaving the inbox.",
        status: "open",
        source: "in-app"
      },
      project: %{
        name: "lantern-ui",
        summary: "Dense-app primitives for Linear-shaped pages",
        completed: 7,
        scope: 19
      },
      stats: %{apps: 3, databases: 2, environments: 2},
      children: [
        %{
          title: "Visible progress ring",
          identifier: "#241",
          href: "/tickets/241",
          status: :in_progress,
          date: "Sep 3"
        },
        %{
          title: "Hub dashboard grouping",
          identifier: "#239",
          href: "/tickets/239",
          status: :done,
          date: "Aug 28"
        }
      ],
      capacity: %{slots: 8, busy: 5, waiting: 3, cost: "$12"}
    }
  end
end
