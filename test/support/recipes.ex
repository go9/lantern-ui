defmodule LanternUI.Recipes do
  @moduledoc false
  use Phoenix.Component
  use LanternUI

  @names ~w(
    linear_list_row
    grouped_list
    flat_table
    record_page
    inbox
    project_overview
    icon_toolbar
    capacity_strip
    conversation
    trace
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
          id: 241,
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
          id: 240,
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
      meta: %{params: %{}, current_page: 1, total_pages: 1, page_size: 20, total_count: 2},
      entities: [
        %{
          id: "API_KEY",
          name: "API_KEY",
          href: "/entities/API_KEY",
          kind: "secret",
          status: :todo
        },
        %{
          id: "REGION",
          name: "REGION",
          href: "/entities/REGION",
          kind: "config",
          status: :in_progress
        }
      ],
      paths: %{
        all: "/tickets",
        active: "/tickets?scope=active",
        backlog: "/tickets?scope=backlog",
        in_progress: "/tickets?status=in_progress",
        done: "/tickets?show_done=1",
        new_in_progress: "/tickets/new?status=in_progress"
      },
      panel_open: true,
      crumbs: [%{label: "Tickets", navigate: "/tickets"}],
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
      capacity: %{slots: 8, busy: 5, waiting: 3, cost: "$12"},
      threads: [
        %{
          identifier: "ask-12",
          title: "Index the docs bucket",
          preview: "Approve the plan, then I will embed the selected files.",
          href: "/inbox/ask-12",
          initials: "AI",
          unread: nil,
          date: "2m",
          selected: true
        },
        %{
          identifier: "ask-11",
          title: "Why did deploy fail?",
          preview: "The build image is missing mix.",
          href: "/inbox/ask-11",
          initials: "JO",
          unread: 2,
          date: "1h",
          selected: false
        }
      ],
      thread: %{
        title: "Index the docs bucket",
        meta: "Ask · running"
      },
      messages: [
        %{
          id: "m1",
          role: :user,
          author: "You",
          initials: "JO",
          content: "Index the docs bucket, skip fixtures.",
          at: "2m ago"
        },
        %{
          id: "m2",
          role: :assistant,
          author: "Assistant",
          initials: "AI",
          content: "I will embed selected files and skip the fixture prefix.",
          at: "1m ago"
        }
      ],
      streaming: false,
      draft: "Ship the plan as written.",
      send_error: "The run rejected this message. Edit the draft and send again.",
      action: %{
        id: "plan-4",
        title: "Approve indexing plan",
        summary: "12 files · skip fixtures/",
        body: "Embed selected Markdown. No provider tokens in the fixture."
      },
      run: %{
        title: "Index run",
        summary: "docs bucket · 12 files",
        state: :live
      },
      follow: true,
      events: [
        %{
          id: "e1",
          title: "queued",
          label: "Queued",
          at: "12:04:01",
          status: :done,
          open: false,
          anchor: false,
          detail: nil,
          channel: nil,
          severity: :neutral
        },
        %{
          id: "e2",
          title: "embed",
          label: "Running",
          at: "12:04:08",
          status: :active,
          open: true,
          anchor: false,
          detail: "embedded 4/12 files",
          channel: "embed",
          severity: :info
        },
        %{
          id: "e3",
          title: "index",
          label: "Pending",
          at: "12:04:09",
          status: :pending,
          open: false,
          anchor: true,
          detail: nil,
          channel: nil,
          severity: :neutral
        }
      ]
    }
  end
end
