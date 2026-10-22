defmodule LanternUI.QA.RecipePagesLive do
  @moduledoc false
  # The five page recipes in the shadcn app preset. `?page=index|detail|settings|form|empty`,
  # `?state=rows|loading|empty|nomatch|error` (index), `?dirty=1` (settings/form), `?nav=1`
  # (settings with section nav), `?theme=dark`. `test/qa/recipe_pages.mjs` measures it.
  use Phoenix.LiveView
  use LanternUI

  @rows [
    %{id: "acme", name: "Acme storefront", repo: "acme/storefront", state: "Synced", tickets: 4},
    %{id: "beacon", name: "Beacon API", repo: "acme/beacon", state: "Stale", tickets: 12},
    %{id: "comet", name: "Comet docs", repo: "acme/comet", state: "Off", tickets: 2},
    %{id: "delta", name: "Delta mobile", repo: "acme/delta", state: "Synced", tickets: 7}
  ]

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    state = params["state"] || "rows"

    {:noreply,
     assign(socket,
       page: params["page"] || "index",
       state: state,
       rows: if(state == "rows", do: @rows, else: []),
       dirty: params["dirty"] == "1",
       nav: params["nav"] == "1",
       dark?: params["theme"] == "dark",
       form:
         to_form(%{"name" => "Atlas", "slug" => "atlas", "visibility" => "private"}, as: :project),
       meta: %{params: params, flop: %{order_by: [:name], order_directions: [:asc]}}
     )}
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp title("index"), do: "Projects"
  defp title("detail"), do: "Atlas"
  defp title("settings"), do: "Settings"
  defp title("form"), do: "New project"
  defp title("empty"), do: "Empty states"

  def render(assigns) do
    ~H"""
    <style>
      html { font-size: 14px; }
    </style>
    <div
      id="recipe-scope"
      class={@dark? && "dark"}
      data-lantern-theme="shadcn"
      data-lantern-preset="app"
      style="background: var(--lantern-surface); color: var(--lantern-fg); font-family: var(--lantern-font); min-height: 100vh;"
    >
      <.app_shell id="recipe-shell" compact nav_label="Main">
        <:brand>Flicker</:brand>
        <:header>
          <.breadcrumb aria_label="Breadcrumb">
            <:item :if={@page in ~w(detail settings)} navigate="/recipe_pages">Projects</:item>
            <:item current>{title(@page)}</:item>
          </.breadcrumb>
        </:header>
        <:sidebar>
          <.nav_item id="nav-projects" label="Projects" icon="folder" navigate="/recipe_pages" active />
        </:sidebar>
        <.page_shell id="recipe-page" layout="bare" title={title(@page)}>
          {render_page(assigns)}
        </.page_shell>
      </.app_shell>
    </div>
    """
  end

  defp render_page(%{page: "index"} = assigns) do
    ~H"""
    <.page_container>
      <.page_heading title="Projects" lead="Everything Flicker is watching for you.">
        <:actions><.button size="sm" variant="solid">New project</.button></:actions>
      </.page_heading>
      <.index_toolbar>
        <:search>
          <.input id="recipe-q" name="q" type="search" size="sm" placeholder="Search projects" />
        </:search>
        <:views>
          <.tabs_list
            id="recipe-view"
            variant="segmented"
            size="sm"
            active_tab="table"
            aria-label="View"
          >
            <:tab name="table" phx-click="noop">Table</:tab>
            <:tab name="grid" phx-click="noop">Grid</:tab>
          </.tabs_list>
        </:views>
        <:filters><.button size="sm" variant="outline">Filters</.button></:filters>
      </.index_toolbar>
      <.skeleton :if={@state == "loading"} label="Loading projects" style="height: 10rem" />
      <.empty_state :if={@state == "empty"} kind="first_use" title="No projects yet">
        Connect a repository and Flicker starts indexing it.
        <:action><.button size="sm" variant="solid">New project</.button></:action>
      </.empty_state>
      <.empty_state :if={@state == "nomatch"} kind="no_match" title="No projects match">
        Nothing matches “zeta” with these filters.
        <:action><.button size="sm" variant="outline">Clear filters</.button></:action>
      </.empty_state>
      <.empty_state :if={@state == "error"} kind="error" title="Projects did not load">
        Check your connection and try again.
        <:action><.button size="sm" variant="outline">Retry</.button></:action>
      </.empty_state>
      <.data_table
        :if={@state == "rows"}
        id="recipe-projects"
        rows={@rows}
        meta={@meta}
        path="/recipe_pages"
        show_checkboxes={false}
        column_settings={false}
        pagination={false}
        active_view="table"
        row_navigate={fn row -> "/recipe_pages?page=detail&p=#{row.id}" end}
      >
        <:col :let={row} field={:name} label="Project">{row.name}</:col>
        <:col :let={row} label="Repository"><span class="lui-mono">{row.repo}</span></:col>
        <:col :let={row} label="Index">{row.state}</:col>
        <:col :let={row} label="Tickets">{row.tickets}</:col>
        <:row_action :let={row}>
          <.button size="xs" variant="outline" label={"Open #{row.name}"}>Open</.button>
        </:row_action>
      </.data_table>
    </.page_container>
    """
  end

  defp render_page(%{page: "detail"} = assigns) do
    ~H"""
    <.page_container>
      <.page_heading title="Atlas" lead="Storefront monorepo, indexed 4 minutes ago.">
        <:actions>
          <.button size="sm" variant="outline">Archive</.button>
          <.button size="sm" variant="solid">Open work</.button>
        </:actions>
      </.page_heading>
      <.detail_layout>
        <.page_section id="recent" title="Recent tickets" description="Updated in the last week.">
          <.data_table
            id="recipe-tickets"
            rows={@rows}
            meta={@meta}
            path="/recipe_pages"
            show_checkboxes={false}
            column_settings={false}
            pagination={false}
            search_field={nil}
            active_view="table"
          >
            <:col :let={row} label="Ticket">{row.name}</:col>
            <:col :let={row} label="State">{row.state}</:col>
            <:col :let={row} label="Open">{row.tickets}</:col>
          </.data_table>
        </.page_section>
        <.page_section id="envs" title="Environments">
          <.description_list columns={1}>
            <:item label="Production">atlas-prod, healthy</:item>
            <:item label="Staging">atlas-stg, 2 changes pending</:item>
          </.description_list>
        </.page_section>
        <:rail>
          <.page_section id="props" title="Properties">
            <.description_list columns={1}>
              <:item label="Owner">Ada Lovelace</:item>
              <:item label="Created">12 Oct 2026</:item>
              <:item label="Database">atlas-db</:item>
            </.description_list>
          </.page_section>
        </:rail>
      </.detail_layout>
    </.page_container>
    """
  end

  defp render_page(%{page: "settings"} = assigns) do
    ~H"""
    <.page_container>
      <.settings_page layout="stacked" title="Settings" subtitle="Project identity and defaults.">
        <:nav :if={@nav} patch="/recipe_pages?page=settings&nav=1" active>General</:nav>
        <:nav :if={@nav} patch="/recipe_pages?page=settings&nav=1">Repositories</:nav>
        <:nav :if={@nav} patch="/recipe_pages?page=settings&nav=1">Keys</:nav>
        <.settings_form
          id="project"
          for={@form}
          dirty={@dirty}
          title="Project"
          description="How this project appears across Flicker."
          phx-change="noop"
          phx-submit="noop"
        >
          <.input field={@form[:name]} label="Name" size="sm" />
          <.input
            field={@form[:slug]}
            label="Slug"
            size="sm"
            readonly
            help_text="The slug cannot change."
          />
        </.settings_form>
        <.settings_form
          id="visibility"
          for={@form}
          dirty={false}
          title="Visibility"
          description="Who can see this project."
          phx-change="noop"
          phx-submit="noop"
        >
          <.select
            native
            id="vis"
            name="visibility"
            label="Visibility"
            size="sm"
            options={[{"Private", "private"}, {"Organisation", "org"}]}
            value="private"
          />
        </.settings_form>
        <.danger_zone>
          <.danger_zone_item
            title="Remove Atlas"
            description="Deletes its index and revokes its keys. This cannot be undone."
          >
            <:action>
              <.button size="sm" variant="outline" color="danger">Remove project</.button>
            </:action>
          </.danger_zone_item>
        </.danger_zone>
      </.settings_page>
    </.page_container>
    """
  end

  defp render_page(%{page: "form"} = assigns) do
    ~H"""
    <.page_container width="narrow">
      <.page_heading title="New project" lead="Name it, then connect a repository." />
      <.form for={@form} phx-change="noop" phx-submit="noop" class="lui-form-stack">
        <.form_group legend="Project" description="Shown in the sidebar and in breadcrumbs.">
          <.input field={@form[:name]} label="Name" size="sm" />
          <.input
            id="project_slug"
            name="project[slug]"
            label="Slug"
            size="sm"
            value="atlas store"
            errors={["can only contain lowercase letters, numbers and dashes"]}
          />
        </.form_group>
        <.form_group legend="Defaults" columns={2}>
          <.input
            id="project_branch"
            name="project[branch]"
            label="Default branch"
            size="sm"
            value="main"
          />
          <.input
            id="project_region"
            name="project[region]"
            label="Region"
            size="sm"
            value="iad"
            help_text="Where the index lives."
          />
        </.form_group>
        <.form_actions>
          <.button size="sm" variant="ghost" type="button">Cancel</.button>
          <.button size="sm" variant="solid" type="submit">Create project</.button>
        </.form_actions>
      </.form>
    </.page_container>
    """
  end

  defp render_page(%{page: "empty"} = assigns) do
    ~H"""
    <.page_container>
      <.page_heading title="Empty states" lead="One icon, one sentence, one action." />
      <.empty_state kind="first_use" title="No keys yet">
        Create a key so agents can reach this project.
        <:action><.button size="sm" variant="solid">New key</.button></:action>
      </.empty_state>
      <.empty_state kind="no_match" title="No results">
        Nothing matches these filters.
        <:action><.button size="sm" variant="outline">Clear filters</.button></:action>
      </.empty_state>
      <.empty_state kind="error" title="Keys did not load">
        Try again in a moment.
        <:action><.button size="sm" variant="outline">Retry</.button></:action>
      </.empty_state>
      <.empty_state kind="restricted" title="You cannot see keys">
        Ask an organisation admin for access.
      </.empty_state>
    </.page_container>
    """
  end
end
