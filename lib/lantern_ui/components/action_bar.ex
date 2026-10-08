defmodule LanternUI.Components.ActionBar do
  @moduledoc """
  Floating page actions with inline promotion and a complete overflow menu.

  Actions are rendered both inline and in the More menu. CSS controls which
  inline copies are visible at each container width; no DOM nodes are moved.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Alert
  alias LanternUI.Components.Button
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Menu
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "Stable id for the promotion and dismissal hook.")
  attr(:actions, :list, default: [], doc: "Page actions as descriptor maps.")
  attr(:notice, :map, default: nil, doc: "Optional dismissible notice map.")
  attr(:dismissed, :boolean, default: false, doc: "Server-owned notice dismissal state.")

  attr(:on_dismiss, :string,
    default: nil,
    doc: "LiveView event for notice dismissal; receives the notice id."
  )

  attr(:more_actions_label, :string,
    default: "More actions",
    doc: "Accessible label for the overflow action menu."
  )

  attr(:dismiss_label, :string,
    default: "Dismiss notice",
    doc: "Accessible label for the notice dismiss control."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML and LiveView attributes passed through.")

  @doc """
  Renders each action inline and in the Zag `More actions` menu. Inline promotion
  is ordered by descending `priority`; disabled and `promotable: false` actions
  remain in the menu only. The observed bar width sets a CSS-pixel promotion tier
  (`> 1100`: 3, `740–1100`: 2, `< 740`: 1), also exposed as `data-promoted`.
  Action maps accept `id`, `label`, `icon`, `priority`,
  `enabled`, `disabled_reason`, `promotable`, `destructive`, `navigate`, `patch`,
  `href`, `phx-click`, `phx-target`, and `phx-value-*` keys. All actions remain
  available in the menu at every width.

  An optional notice map accepts `id`, `tone`, `title`, and `body`. The dismiss
  button sends `on_dismiss` with the notice id through the LiveView event. Notice
  announcements use `role="status"`, except an initially visible danger notice,
  which uses `role="alert"`.
  """
  def action_bar(assigns) do
    {actions, menu_actions} = prepare_actions(assigns.actions)
    notice = normalize_notice(assigns.notice)

    assigns =
      assigns
      |> assign(:inline_actions, actions)
      |> assign(:menu_actions, menu_actions)
      |> assign(:notice_data, notice)
      |> assign(:dismiss_command, dismiss_command(assigns.on_dismiss, notice))
      |> assign(:menu_id, "#{assigns.id}-menu")

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-action-bar", @class])}
      phx-hook="LanternActionBar"
      data-action-bar
      data-dismissal-event={@on_dismiss}
      {@rest}
    >
      <Alert.alert
        :if={@notice_data}
        id={"#{@id}-notice"}
        class="lui-action-bar-notice"
        color={@notice_data.tone}
        tone_slots
        role={if @notice_data.tone == "danger" and not @dismissed, do: "alert", else: "status"}
        title={@notice_data.title}
        subtitle={@notice_data.body}
        hide_close={false}
        dismiss_label={@dismiss_label}
        on_close={@dismiss_command}
        hidden={@dismissed}
        data-action-bar-notice
        data-dismissal-key={"#{@id}:#{@notice_data.id}"}
        data-notice-id={@notice_data.id}
        data-server-dismissed={to_string(@dismissed)}
      />

      <div :if={@inline_actions != []} class="lui-action-bar-actions">
        <div class="lui-action-bar-inline" data-part="inline-actions">
          <span
            :for={action <- @inline_actions}
            class="lui-action-bar-action"
            data-action-id={action.id}
            data-promoted-index={action.promoted_index}
            data-has-icon={action.icon && "true"}
          >
            <Button.button
              id={"#{@id}-#{action.id}-inline"}
              size="sm"
              variant="outline"
              color={if(action.destructive, do: "danger", else: "primary")}
              label={action.label}
              disabled={!action.enabled}
              navigate={action.navigate}
              patch={action.patch}
              href={action.href}
              {action.rest_attrs}
            >
              <Icon.icon :if={action.icon} name={action.icon} />
              <span class="lui-action-bar-label">{action.label}</span>
            </Button.button>
          </span>
        </div>

        <Menu.menu
          id={@menu_id}
          placement="bottom-end"
          container_class="lui-action-bar-menu"
          trigger_class="lui-action-bar-more-trigger"
        >
          <:trigger>
            <Icon.icon name="ellipsis-horizontal" />
            <span class="lui-sr-only">{@more_actions_label}</span>
          </:trigger>
          <Menu.menu_item
            :for={action <- @menu_actions}
            id={"#{@id}-#{action.id}-menu"}
            disabled={!action.enabled}
            navigate={action.navigate}
            patch={action.patch}
            href={action.href}
            {action.rest_attrs}
            data-action-id={action.id}
            data-tone={action.destructive && "danger"}
          >
            <span class="lui-action-bar-menu-item">
              <Icon.icon :if={action.icon} name={action.icon} />
              <span class="lui-action-bar-menu-copy">
                <span>{action.label}</span>
                <small :if={!action.enabled && action.disabled_reason}>
                  {action.disabled_reason}
                </small>
              </span>
            </span>
          </Menu.menu_item>
        </Menu.menu>
      </div>
    </div>
    """
  end

  defp prepare_actions(actions) do
    normalized =
      actions
      |> Enum.with_index()
      |> Enum.map(fn {action, index} -> normalize_action(action, index) end)

    promoted_indices =
      normalized
      |> Enum.filter(&(&1.enabled and &1.promotable))
      |> Enum.sort_by(fn action -> {-action.priority, action.source_index} end)
      |> Enum.with_index(1)
      |> Map.new(fn {action, promoted_index} -> {action.source_index, promoted_index} end)

    inline_actions =
      normalized
      |> Enum.map(fn action ->
        Map.put(action, :promoted_index, Map.get(promoted_indices, action.source_index, 0))
      end)
      |> Enum.sort_by(fn action ->
        if action.promoted_index > 0 do
          {0, action.promoted_index}
        else
          {1, action.source_index}
        end
      end)

    menu_actions =
      normalized
      |> Enum.sort_by(fn action -> {action.destructive, action.source_index} end)

    {inline_actions, menu_actions}
  end

  defp normalize_action(action, index) do
    id =
      case value(action, :id) do
        nil -> "action-#{index + 1}"
        "" -> "action-#{index + 1}"
        id -> to_string(id)
      end

    priority = value(action, :priority, 0)
    priority = if is_number(priority), do: priority, else: 0
    enabled = value(action, :enabled, true) != false
    promotable = value(action, :promotable, true) != false

    %{
      id: id,
      label: to_string(value(action, :label, "")),
      icon: value(action, :icon),
      priority: priority,
      enabled: enabled,
      disabled_reason: value(action, :disabled_reason),
      promotable: promotable,
      destructive: value(action, :destructive, false) == true,
      rest_attrs: action_rest_attrs(action, id),
      navigate: value(action, :navigate),
      patch: value(action, :patch),
      href: value(action, :href),
      source_index: index,
      promoted_index: 0
    }
  end

  defp action_rest_attrs(action, id) do
    base = %{
      "phx-value-id" => id,
      "phx-click" => value(action, :"phx-click"),
      "phx-target" => value(action, :"phx-target"),
      "data-confirm" => value(action, :"data-confirm")
    }

    action
    |> Enum.reduce(base, fn {key, value}, attrs ->
      key = to_string(key)
      if String.starts_with?(key, "phx-value-"), do: Map.put(attrs, key, value), else: attrs
    end)
  end

  defp normalize_notice(nil), do: nil

  defp normalize_notice(notice) when is_map(notice) do
    tone = value(notice, :tone, "neutral")
    tone = if tone in ~w(neutral info success warning danger promo), do: tone, else: "neutral"

    %{
      id: to_string(value(notice, :id, "notice")),
      tone: tone,
      title: to_string(value(notice, :title, "")),
      body: to_string(value(notice, :body, ""))
    }
  end

  defp normalize_notice(_), do: nil

  defp dismiss_command(event, %{id: id}) when is_binary(event) and event != "" do
    JS.push(event, value: %{"id" => id})
  end

  defp dismiss_command(_, _), do: nil

  defp value(map, key, default \\ nil)

  defp value(map, key, default) when is_map(map) do
    case Map.get(map, key) do
      nil ->
        case Map.get(map, Atom.to_string(key)) do
          nil -> default
          value -> value
        end

      value ->
        value
    end
  end

  defp value(_value, _key, default), do: default
end
