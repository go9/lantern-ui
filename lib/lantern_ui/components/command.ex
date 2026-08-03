defmodule LanternUI.Components.Command do
  @moduledoc """
  Command palette (⌘K dialog) — a modal combobox over a listbox of actions.

  There is **no Fluxon equivalent**; the structure mirrors shadcn's Base UI
  `Command` (input → list → groups → items → empty), translated onto Lantern's
  dialog runtime and tokens.

  ## Filtering is the consumer's job

  The component never filters its own children. It renders exactly the items it
  is handed and reports the query upward, so a LiveView can answer from a
  database, a search index, or memory:

      <.command id="cmd-k" on_search="command_search" on_select="command_select">
        <.command_group label="Tickets">
          <.command_item :for={t <- @results} value={t.id}>
            {t.title}
            <:shortcut>{t.number}</:shortcut>
          </.command_item>
        </.command_group>
        <.command_empty :if={@results == []}>No matches for "{@query}"</.command_empty>
      </.command>

      def handle_event("command_search", %{"query" => q}, socket), do: ...
      def handle_event("command_select", %{"value" => v}, socket), do: ...

  ## Events, and why they are not `phx-` attributes

  The `LanternCommand` hook pushes `on_search` / `on_select` itself. Nothing in
  this component carries a `phx-change`, `phx-submit`, or a `<form>` element, so
  mounting the palette in a global app shell cannot make a host app's own
  `element("form")` / `form[phx-change=...]` test selectors ambiguous. Event
  names default to the `command_*` namespace for the same reason.

  Payloads:

    * `on_search` → `%{"query" => query}` (debounced by `debounce`, in ms)
    * `on_select` → `%{"value" => value}` — pushed only for items that do not
      carry their own `phx-click`, so per-item bindings are never double-fired.

  ## Opening and closing

  Shares the dialog contract with `LanternUI.Components.Modal`:

      <.button phx-click={LanternUI.open_dialog("cmd-k")}>Search…</.button>
      {:noreply, LanternUI.open_dialog(socket, "cmd-k")}

  plus the built-in ⌘K / Ctrl+K hotkey (`hotkey="k"`, set `hotkey={nil}` to
  disable). Focus is trapped while open and restored to the previously focused
  element on close. Escape and a backdrop click close by default.

  ## Keyboard

  `↑`/`↓` move the highlight, `Home`/`End` jump, `Enter` activates the
  highlighted item, `Escape` closes. Focus stays in the input; the active item
  is published with `aria-activedescendant` (this is a combobox, not the roving
  DOM focus used by `menu`/`select`).
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "Stable DOM id used by open_dialog/close_dialog.")
  attr(:open, :boolean, default: false, doc: "Render already open (server-driven palettes).")

  attr(:label, :string,
    default: "Command palette",
    doc: "Accessible name for the dialog and the results listbox."
  )

  attr(:placeholder, :string,
    default: "Type a command or search…",
    doc: "Search input placeholder."
  )

  attr(:target, :any,
    default: nil,
    doc: """
    LiveComponent to send `on_search`/`on_select` to, as `@myself`.

    Required when the palette is rendered from INSIDE a LiveComponent: without
    it the hook pushes to the parent LiveView, which then has to define
    handlers it has no business owning. A global palette in an app shell is
    almost always a LiveComponent, so this is the normal case rather than an
    edge one.
    """
  )

  attr(:on_search, :string,
    default: "command_search",
    doc: "LiveView event pushed with `%{\"query\" => query}`. `nil` disables searching."
  )

  attr(:on_select, :string,
    default: "command_select",
    doc:
      "LiveView event pushed with `%{\"value\" => value}` when an item without its own " <>
        "`phx-click` is activated. `nil` disables it."
  )

  attr(:debounce, :integer, default: 200, doc: "Search debounce in milliseconds.")

  attr(:hotkey, :string,
    default: "k",
    doc: "Key that opens the palette with Meta/Ctrl. `nil` disables the global hotkey."
  )

  attr(:loading, :boolean, default: false, doc: "Show the loading row above the results.")

  attr(:search_on_open, :boolean,
    default: true,
    doc: "Push `on_search` with the current query when the palette opens."
  )

  attr(:close_on_esc, :boolean, default: true, doc: "Close when Escape is pressed.")

  attr(:close_on_outside_click, :boolean,
    default: true,
    doc: "Close when the backdrop is clicked."
  )

  attr(:close_on_select, :boolean,
    default: true,
    doc: "Close the palette after an item is chosen."
  )

  attr(:class, :any, default: nil, doc: "Extra classes on the dialog panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the overlay root.")
  attr(:backdrop_class, :any, default: nil, doc: "Extra classes on the dimmed backdrop.")
  attr(:list_class, :any, default: nil, doc: "Extra classes on the scrollable results list.")

  attr(:rest, :global,
    doc: "Arbitrary HTML/`phx-*` attributes passed through to the overlay root."
  )

  slot(:inner_block, required: true, doc: "Results: groups, items, separators, empty state.")
  slot(:footer, doc: "Sticky footer under the results (hints, counts).")

  def command(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-command", @container_class])}
      phx-hook="LanternCommand"
      data-open={@open || nil}
      data-hotkey={@hotkey}
      data-debounce={@debounce}
      data-target={command_target(@target)}
      {phx_target_attr(@target)}
      data-on-search={@on_search}
      data-on-select={@on_select}
      data-search-on-open={to_string(@search_on_open)}
      data-close-on-esc={to_string(@close_on_esc)}
      data-close-on-outside={to_string(@close_on_outside_click)}
      data-close-on-select={to_string(@close_on_select)}
      hidden={!@open}
      {@rest}
    >
      <div class={Class.merge(["lui-command-backdrop", @backdrop_class])} data-part="backdrop"></div>
      <div
        class={Class.merge(["lui-command-panel", @class])}
        data-part="panel"
        role="dialog"
        aria-modal="true"
        aria-label={@label}
      >
        <div class="lui-command-header">
          <Icon.icon name="magnifying-glass" class="lui-command-search-icon" />
          <input
            type="text"
            id={"#{@id}-input"}
            class="lui-command-input"
            data-part="input"
            placeholder={@placeholder}
            autocomplete="off"
            spellcheck="false"
            role="combobox"
            aria-expanded="true"
            aria-autocomplete="list"
            aria-controls={"#{@id}-list"}
          />
          <kbd class="lui-command-esc" aria-hidden="true">esc</kbd>
        </div>

        <div
          class="lui-command-loading"
          data-part="loading"
          role="status"
          aria-label="Loading results"
          hidden={!@loading}
        >
          <span class="lui-command-spinner" aria-hidden="true"></span>
        </div>

        <div
          id={"#{@id}-list"}
          class={Class.merge(["lui-command-list", @list_class])}
          data-part="list"
          role="listbox"
          aria-label={@label}
        >
          {render_slot(@inner_block)}
        </div>

        <div :if={@footer != []} class="lui-command-footer">{render_slot(@footer)}</div>
      </div>
    </div>
    """
  end

  attr(:id, :any, default: nil, doc: "Element id; auto-generated when omitted.")
  attr(:label, :string, default: nil, doc: "Section heading rendered above the items.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the group.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Items belonging to this group.")

  def command_group(assigns) do
    # Not assign_new/3: the attr default already puts :id in assigns as nil,
    # so assign_new would never fire and the label idref would dangle.
    assigns = assign(assigns, :id, assigns.id || unique_id("group"))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-command-group", @class])}
      data-part="group"
      role="group"
      aria-labelledby={@label && "#{@id}-label"}
      {@rest}
    >
      <div :if={@label} id={"#{@id}-label"} class="lui-command-group-label">{@label}</div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:id, :any, default: nil, doc: "Element id; auto-generated when omitted.")

  attr(:value, :any,
    default: nil,
    doc: "Value sent as `%{\"value\" => value}` when the item is selected."
  )

  attr(:disabled, :boolean, default: false, doc: "Render the row unselectable.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")

  attr(:rest, :global,
    include: ~w(phx-click phx-target phx-value-id),
    doc:
      "Arbitrary HTML/`phx-*` attributes. An item with its own `phx-click` does not " <>
        "also push the palette's `on_select` event."
  )

  slot(:icon, doc: "Leading icon or avatar.")
  slot(:description, doc: "Secondary line under the label.")
  slot(:shortcut, doc: "Trailing keyboard hint or badge.")
  slot(:inner_block, required: true, doc: "Item label.")

  def command_item(assigns) do
    assigns = assign(assigns, :id, assigns.id || unique_id("item"))

    ~H"""
    <button
      type="button"
      id={@id}
      class={Class.merge(["lui-command-item", @class])}
      data-part="item"
      data-value={@value && to_string(@value)}
      role="option"
      aria-selected="false"
      aria-disabled={@disabled && "true"}
      disabled={@disabled}
      tabindex="-1"
      {@rest}
    >
      <span :for={slot <- @icon} class="lui-command-item-icon">{render_slot(slot)}</span>
      <span class="lui-command-item-body">
        <span class="lui-command-item-label">{render_slot(@inner_block)}</span>
        <span :for={slot <- @description} class="lui-command-item-description">
          {render_slot(slot)}
        </span>
      </span>
      <span :for={slot <- @shortcut} class="lui-command-shortcut">{render_slot(slot)}</span>
    </button>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the empty state.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Empty-state copy.")

  def command_empty(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-command-empty", @class])}
      data-part="empty"
      role="status"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the separator.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def command_separator(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-command-separator", @class])}
      data-part="separator"
      role="separator"
      {@rest}
    >
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the shortcut hint.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Keyboard hint text, e.g. `⌘K`.")

  def command_shortcut(assigns) do
    ~H"""
    <kbd class={Class.merge(["lui-command-shortcut", @class])} {@rest}>
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  # LiveView renders `@myself` as a CID struct; its string form is what
  # pushEventTo accepts. A plain selector string passes through unchanged.
  # Also emit a real `phx-target`. `data-target` drives the hook's own
  # pushEventTo, but LiveView — and LiveViewTest — only understand phx-target,
  # so without it a consumer cannot test its own palette: events route to the
  # parent LiveView and the component's handlers never run.
  defp phx_target_attr(nil), do: %{}
  defp phx_target_attr(target), do: %{"phx-target" => target}

  defp command_target(nil), do: nil
  defp command_target(target), do: to_string(target)

  defp unique_id(part), do: "lui-cmd-#{part}-#{System.unique_integer([:positive])}"
end
