defmodule LanternUI.KbdTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Kbd

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "kbd/1" do
    test "renders default outline variant and sm size with inner block" do
      html =
        render(fn assigns ->
          ~H"""
          <Kbd.kbd>⌘K</Kbd.kbd>
          """
        end)

      assert html =~ ~s(<kbd)
      assert html =~ ~s(class="lui-kbd")
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-size="sm")
      assert html =~ "⌘K"
    end

    test "renders custom size and variant" do
      for size <- ~w(xs sm md lg),
          variant <- ~w(outline subtle solid ghost) do
        html =
          render(
            fn assigns ->
              ~H"""
              <Kbd.kbd size={@size} variant={@variant}>Esc</Kbd.kbd>
              """
            end,
            %{size: size, variant: variant}
          )

        assert html =~ ~s(data-size="#{size}")
        assert html =~ ~s(data-variant="#{variant}")
        assert html =~ "Esc"
      end
    end

    test "renders keys string attribute" do
      html =
        render(fn assigns ->
          ~H"""
          <Kbd.kbd keys="Shift+E" />
          """
        end)

      assert html =~ ~s(class="lui-kbd")
      assert html =~ "Shift+E"
    end

    test "renders list of keys into a kbd-group with individual keycaps and symbol mapping" do
      html =
        render(fn assigns ->
          ~H"""
          <Kbd.kbd keys={[:command, "K"]} size="md" variant="subtle" />
          """
        end)

      assert html =~ ~s(<span)
      assert html =~ ~s(class="lui-kbd-group")
      assert html =~ ~s(<kbd class="lui-kbd" data-size="md" data-variant="subtle">⌘</kbd>)
      assert html =~ ~s(<kbd class="lui-kbd" data-size="md" data-variant="subtle">K</kbd>)
    end

    test "merges custom class and passes global rest attributes" do
      html =
        render(fn assigns ->
          ~H"""
          <Kbd.kbd class="custom-kbd" id="shortcut-esc" aria-label="Escape key">Esc</Kbd.kbd>
          """
        end)

      assert html =~ ~s(class="lui-kbd custom-kbd")
      assert html =~ ~s(id="shortcut-esc")
      assert html =~ ~s(aria-label="Escape key")
    end
  end

  describe "kbd_group/1" do
    test "renders a container wrapping multiple kbd elements" do
      html =
        render(fn assigns ->
          ~H"""
          <Kbd.kbd_group id="group-1" class="my-group">
            <Kbd.kbd>Ctrl</Kbd.kbd>
            <span class="lui-kbd-sep">+</span>
            <Kbd.kbd>C</Kbd.kbd>
          </Kbd.kbd_group>
          """
        end)

      assert html =~ ~s(<span class="lui-kbd-group my-group" id="group-1">)
      assert html =~ ~s(Ctrl)
      assert html =~ ~s(class="lui-kbd-sep")
      assert html =~ ~s(C)
    end
  end

  describe "symbol/1" do
    test "maps common atom names to standard keyboard symbols" do
      assert Kbd.symbol(:command) == "⌘"
      assert Kbd.symbol(:cmd) == "⌘"
      assert Kbd.symbol(:shift) == "⇧"
      assert Kbd.symbol(:option) == "⌥"
      assert Kbd.symbol(:alt) == "⌥"
      assert Kbd.symbol(:control) == "⌃"
      assert Kbd.symbol(:ctrl) == "⌃"
      assert Kbd.symbol(:enter) == "↵"
      assert Kbd.symbol(:escape) == "Esc"
      assert Kbd.symbol(:tab) == "⇥"
      assert Kbd.symbol(:up) == "↑"
      assert Kbd.symbol(:down) == "↓"
      assert Kbd.symbol(:left) == "←"
      assert Kbd.symbol(:right) == "→"
      assert Kbd.symbol("custom") == "custom"
    end
  end

  describe "LanternUI registry" do
    test "registers :kbd pointing to LanternUI.Components.Kbd" do
      assert LanternUI.__components__()[:kbd] == LanternUI.Components.Kbd
    end
  end
end
