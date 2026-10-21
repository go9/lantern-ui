defmodule LanternUI.QA.ProjectNavLive do
  @moduledoc false
  # Demo + browser fixture for flicker #3880: a project sidebar built only from
  # released-shape lantern parts. Pinned and All projects are peers; each
  # project row is an identity link, a disclosure for its pages and a pin
  # button. Disclosure state is keyed by the (simulated, server-trusted) user
  # and org. The page body composes the chat kit with `on_seen`.
  #
  #   /project_nav?user=1&org=acme&theme=dark&project=atlas&page=runs
  use Phoenix.LiveView
  use LanternUI

  @projects ~w(atlas beacon comet delta)

  def mount(params, _session, socket) do
    messages = for n <- 1..12, do: %{id: "m#{n}", author: author(n), body: "Message #{n}"}

    {:ok,
     assign(socket,
       theme: if(params["theme"] == "dark", do: "dark", else: "light"),
       user: params["user"] || "1",
       org: params["org"] || "acme",
       inset: params["inset"] in ~w(1 true),
       pinned: ~w(atlas beacon),
       messages: messages,
       seen: nil
     )}
  end

  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(socket,
       project: params["project"] || "atlas",
       page: params["page"] || "overview"
     )}
  end

  def handle_event("pin", %{"id" => id}, socket) when id in @projects do
    {:noreply, update(socket, :pinned, &Enum.uniq(&1 ++ [id]))}
  end

  def handle_event("unpin", %{"id" => id}, socket) do
    {:noreply, update(socket, :pinned, &List.delete(&1, id))}
  end

  def handle_event("seen", %{"message_id" => id}, socket) do
    {:noreply, assign(socket, :seen, id)}
  end

  def handle_event("append", _params, socket) do
    n = length(socket.assigns.messages) + 1
    msg = %{id: "m#{n}", author: author(n), body: "Message #{n}"}
    {:noreply, update(socket, :messages, &(&1 ++ [msg]))}
  end

  defp author(n), do: Enum.at(["user", "agent", "system"], rem(n, 3))

  defp key(assigns, group), do: "u#{assigns.user}:o#{assigns.org}:#{group}"

  defp path(assigns, project, page \\ "overview") do
    "/project_nav?" <>
      URI.encode_query(
        user: assigns.user,
        org: assigns.org,
        theme: assigns.theme,
        project: project,
        page: page
      )
  end

  defp name(id), do: String.capitalize(id)

  def render(assigns) do
    assigns =
      assign(assigns,
        # The current project always shows once, pinned or not.
        rows: Enum.uniq(assigns.pinned ++ [assigns.project]),
        all: @projects
      )

    ~H"""
    <div
      id="qa-project-nav-theme"
      class={@theme == "dark" && "dark"}
      style="min-height: 100vh; background: var(--lantern-bg);"
    >
      <.app_shell id="qa-project-nav" nav_label="Project navigation" inset={@inset}>
        <:brand>Lantern QA</:brand>
        <:sidebar_header>
          <.menu id="qa-org-menu" placement="bottom-start">
            <:trigger>{String.capitalize(@org)}</:trigger>
            <.menu_item navigate={"/project_nav?user=#{@user}&org=acme&theme=#{@theme}"}>
              Acme
            </.menu_item>
            <.menu_item navigate={"/project_nav?user=#{@user}&org=globex&theme=#{@theme}"}>
              Globex
            </.menu_item>
          </.menu>
        </:sidebar_header>
        <:sidebar>
          <.nav_group label="Pinned">
            <.nav_item
              :for={id <- @rows}
              id={"qa-project-#{id}"}
              label={name(id)}
              icon="folder"
              navigate={path(assigns, id)}
              storage_key={key(assigns, "project-#{id}")}
              expanded={id == @project}
            >
              <:action
                label={if id in @pinned, do: "Unpin #{name(id)}", else: "Pin #{name(id)}"}
                icon="map-pin"
                pressed={id in @pinned}
                phx-click={if id in @pinned, do: "unpin", else: "pin"}
                phx-value-id={id}
              />
              <:subnav>
                <.nav_item
                  label="Overview"
                  navigate={path(assigns, id)}
                  active={id == @project and @page == "overview"}
                />
                <.nav_item
                  id={"qa-project-#{id}-factory"}
                  label="Factory"
                  storage_key={key(assigns, "project-#{id}-factory")}
                >
                  <:subnav>
                    <.nav_item
                      label="Inbox"
                      navigate={path(assigns, id, "inbox")}
                      badge={if id == "atlas", do: 3}
                      active={id == @project and @page == "inbox"}
                    />
                    <.nav_item
                      label="Runs"
                      navigate={path(assigns, id, "runs")}
                      active={id == @project and @page == "runs"}
                    />
                  </:subnav>
                </.nav_item>
              </:subnav>
            </.nav_item>
          </.nav_group>
          <.nav_group label="All projects">
            <.nav_item
              :for={id <- @all}
              id={"qa-all-#{id}"}
              label={name(id)}
              navigate={path(assigns, id)}
            >
              <:action
                label={if id in @pinned, do: "Unpin #{name(id)}", else: "Pin #{name(id)}"}
                icon="map-pin"
                pressed={id in @pinned}
                phx-click={if id in @pinned, do: "unpin", else: "pin"}
                phx-value-id={id}
              />
            </.nav_item>
          </.nav_group>
        </:sidebar>
        <.page_shell
          id="qa-project-page"
          title={"#{name(@project)} · #{@page}"}
          actions={[%{id: "append", label: "Append message", "phx-click": "append"}]}
        >
          <p id="qa-seen" data-seen={@seen}>Seen up to: {@seen || "none"}</p>
          <div style="height: 20rem; display: flex;">
            <.message_scroller id="qa-thread" label="Conversation" on_seen="seen">
              <.message_scroller_item
                :for={m <- @messages}
                id={"qa-msg-#{m.id}"}
                message_id={m.id}
              >
                <.message
                  align={if m.author == "user", do: "end", else: "start"}
                  tone={if m.author == "user", do: "primary", else: "surface"}
                >
                  <:avatar><.avatar size="sm" initials={String.first(m.author)} /></:avatar>
                  <:header>{m.author}</:header>
                  {m.body}
                </.message>
              </.message_scroller_item>
            </.message_scroller>
          </div>
        </.page_shell>
      </.app_shell>
    </div>
    """
  end
end
