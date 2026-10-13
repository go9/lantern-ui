defmodule LanternUI.QA.SettingsLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"
    {:ok, assign(socket, theme: theme)}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, tab: params["tab"] || "general", nav: params["nav"])}
  end

  def render(assigns) do
    ~H"""
    <div data-lantern-theme={@theme}>
      <.app_shell id="qa-settings-app">
        <:brand>Lantern QA</:brand>
        <:sidebar>
          <.nav_group :if={@nav != "navlist"} label="Workspace">
            <.nav_item label="Dashboard" icon="chart-bar" navigate="/qa" />
            <.nav_item label="User settings" icon="adjustments-horizontal" expanded active>
              <:subnav>
                <.nav_item label="General" patch="/settings" active={@tab == "general"} />
                <.nav_item
                  label="Connection"
                  patch="/settings?tab=connection"
                  active={@tab == "connection"}
                />
                <.nav_item label="Notifications" patch="/settings?tab=notifications" />
              </:subnav>
            </.nav_item>
          </.nav_group>
          <.navlist :if={@nav == "navlist"} heading="Workspace">
            <.navlink icon="chart-bar" navigate="/qa">Dashboard</.navlink>
            <.navlink icon="adjustments-horizontal">
              User settings
              <:item patch="/settings?nav=navlist" active={@tab == "general"}>General</:item>
              <:item patch="/settings?nav=navlist&tab=connection" active={@tab == "connection"}>
                Connection
              </:item>
              <:item patch="/settings?nav=navlist&tab=notifications">Notifications</:item>
            </.navlink>
          </.navlist>
        </:sidebar>
        <.page_shell id="qa-settings-shell" title="User settings">
          <.settings_page
            title="Account & user management"
            subtitle="Manage your account settings and preferences."
          >
            <:tabs>
              <.tabs_list id="qa-settings-tabs" active_tab={@tab} aria-label="Settings">
                <:tab name="general" patch="/settings">General</:tab>
                <:tab name="connection" patch="/settings?tab=connection">Connection</:tab>
              </.tabs_list>
            </:tabs>

            <.settings_section
              id="personal"
              title="Personal information"
              description="Your name and contact details."
            >
              <.input name="first" label="First name" value="John" />
              <.input name="last" label="Last name" value="Doe" />
              <.input name="email" type="email" label="Email" value="john@example.com" />
              <:actions><.button variant="solid">Save changes</.button></:actions>
            </.settings_section>

            <.settings_section id="password" title="Password" description="Change your password.">
              <.input name="current" type="password" label="Current password" />
              <.input name="new" type="password" label="New password" />
              <:actions><.button variant="solid">Save changes</.button></:actions>
            </.settings_section>

            <.danger_zone id="danger" description="These actions cannot be undone.">
              <.danger_zone_item
                title="Delete account"
                description="Removes your account and all of its data."
              >
                <:action><.button variant="solid" color="danger">Delete</.button></:action>
              </.danger_zone_item>
            </.danger_zone>
          </.settings_page>
        </.page_shell>
      </.app_shell>
    </div>
    """
  end
end
