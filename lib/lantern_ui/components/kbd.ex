defmodule LanternUI.Components.Kbd do
  @moduledoc """
  Standalone keyboard shortcut hint `<kbd>` component.

  Renders semantic `<kbd>` keycap badges for keyboard shortcuts, hotkeys,
  and command hints.

  ## Examples

      <.kbd keys={[:command, "K"]} />
      <.kbd size="xs">Esc</.kbd>
      <.kbd variant="outline">Shift+E</.kbd>
      <.kbd keys={[:command, "K"]} />
      <.kbd keys={["Ctrl", "Shift", "P"]} />

      <.kbd_group>
        <.kbd keys={:command} />
        <span class="lui-kbd-sep">+</span>
        <.kbd>K</.kbd>
      </.kbd_group>
  """

  use Phoenix.Component

  alias LanternUI.Class

  @sizes ~w(xs sm md lg)
  @variants ~w(outline subtle solid ghost)

  @symbols %{
    command: "⌘",
    cmd: "⌘",
    shift: "⇧",
    option: "⌥",
    alt: "⌥",
    control: "⌃",
    ctrl: "⌃",
    enter: "↵",
    return: "↵",
    escape: "Esc",
    esc: "Esc",
    tab: "⇥",
    backspace: "⌫",
    delete: "⌦",
    up: "↑",
    down: "↓",
    left: "←",
    right: "→",
    space: "␣"
  }

  attr(:size, :string, default: "sm", values: @sizes, doc: "Size scale for the keycap.")

  attr(:variant, :string,
    default: "outline",
    values: @variants,
    doc: "Surface style of the keycap."
  )

  attr(:keys, :any,
    default: nil,
    doc: "Optional shortcut key or list of shortcut keys (atoms or strings)."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the element.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")
  slot(:inner_block, doc: "Keyboard hint text or key contents.")

  def kbd(%{keys: keys} = assigns) when is_list(keys) do
    assigns = assign(assigns, :computed_class, Class.merge(["lui-kbd-group", assigns.class]))

    ~H"""
    <span
      class={@computed_class}
      role="group"
      aria-label={Enum.map_join(@keys, " + ", &accessible_key_name/1)}
      {@rest}
    >
      <kbd
        :for={k <- @keys}
        class="lui-kbd"
        data-size={@size}
        data-variant={@variant}
        aria-hidden="true"
      >{render_key(k)}</kbd>
    </span>
    """
  end

  def kbd(assigns) do
    assigns = assign(assigns, :computed_class, Class.merge(["lui-kbd", assigns.class]))

    ~H"""
    <kbd
      class={@computed_class}
      data-size={@size}
      data-variant={@variant}
      role={if key_symbol?(@keys), do: "img"}
      aria-label={if key_symbol?(@keys), do: accessible_key_name(@keys)}
      {@rest}
    ><%= if @keys do %>
      <span aria-hidden={if key_symbol?(@keys), do: "true"}>{render_key(@keys)}</span>
    <% else %>
      {render_slot(@inner_block)}
    <% end %></kbd>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the group container.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")
  slot(:inner_block, required: true, doc: "Group of <.kbd> elements and optional separators.")

  def kbd_group(assigns) do
    assigns = assign(assigns, :computed_class, Class.merge(["lui-kbd-group", assigns.class]))

    ~H"""
    <span class={@computed_class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Resolves a symbolic key identifier (atom or binary) to its standard display glyph.

  ## Examples

      iex> LanternUI.Components.Kbd.symbol(:command)
      "⌘"
      iex> LanternUI.Components.Kbd.symbol(:shift)
      "⇧"
      iex> LanternUI.Components.Kbd.symbol("Esc")
      "Esc"
  """
  def symbol(key) when is_atom(key), do: Map.get(@symbols, key, Atom.to_string(key))
  def symbol(key) when is_binary(key), do: key
  def symbol(other), do: to_string(other)

  defp key_symbol?(key), do: symbol(key) in Map.values(@symbols)

  defp accessible_key_name(key) do
    case symbol(key) do
      "⌘" -> "Command"
      "⇧" -> "Shift"
      "⌥" -> "Option"
      "⌃" -> "Control"
      "↵" -> "Enter"
      "⇥" -> "Tab"
      "⌫" -> "Backspace"
      "⌦" -> "Delete"
      "↑" -> "Up arrow"
      "↓" -> "Down arrow"
      "←" -> "Left arrow"
      "→" -> "Right arrow"
      "␣" -> "Space"
      "Esc" -> "Escape"
      other -> other
    end
  end

  defp render_key(key), do: symbol(key)
end
