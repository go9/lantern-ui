defmodule LanternUI.SkeletonTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Skeleton

  defp render(fun) do
    fun.(%{__changed__: nil}) |> rendered_to_string()
  end

  describe "skeleton/1" do
    test "bare skeleton renders byte-identical to v1 with decorative semantics" do
      html =
        render(fn assigns ->
          ~H"""
          <Skeleton.skeleton />
          """
        end)

      assert String.trim(html) ==
               ~s(<span class="lui-skeleton" style="" aria-hidden="true"></span>)

      refute html =~ "data-variant"
      refute html =~ ~s(role="status")
    end

    test "renders text and circle variants as data-variant" do
      html =
        render(fn assigns ->
          ~H"""
          <Skeleton.skeleton variant="text" />
          <Skeleton.skeleton variant="circle" />
          """
        end)

      assert html =~ ~s(data-variant="text")
      assert html =~ ~s(data-variant="circle")
    end

    test "label wraps the skeleton in a polite status region and passes the ARIA gate" do
      html =
        render(fn assigns ->
          ~H"""
          <Skeleton.skeleton label="Loading profile" />
          """
        end)

      assert html =~ ~s(class="lui-skeleton-status")
      assert html =~ ~s(role="status")
      # aria-busy on the status wrapper lets AT withhold the announcement
      # forever (the wrapper is removed, never un-busied) — must stay absent.
      refute html =~ "aria-busy"
      assert html =~ ~s(<span class="lui-sr-only">Loading profile</span>)
      assert html =~ ~s(aria-hidden="true")
      assert ARIAConformance.audit(html) == []
    end

    test "passes through class, style, and global attributes" do
      html =
        render(fn assigns ->
          ~H"""
          <Skeleton.skeleton
            class="is-circle"
            style="width: 3rem; height: 3rem; border-radius: 9999px;"
            id="avatar-skeleton"
            data-shape="avatar"
            phx-click="ignored-while-loading"
          />
          """
        end)

      assert html =~ ~s(class="lui-skeleton is-circle")
      assert html =~ ~s(style="width: 3rem; height: 3rem; border-radius: 9999px;")
      assert html =~ ~s(id="avatar-skeleton")
      assert html =~ ~s(data-shape="avatar")
      assert html =~ ~s(phx-click="ignored-while-loading")
      assert html =~ ~s(aria-hidden="true")
    end

    test "bundled CSS provides standalone geometry, color, pulse, and reduced motion" do
      css = File.read!("priv/static/lantern_ui.css")

      assert css =~ ".lui-skeleton {"
      assert css =~ "width: 100%;"
      assert css =~ "height: 1rem;"
      assert css =~ "#e5e7eb"
      assert css =~ "animation: lui-skeleton-pulse"
      assert css =~ "@keyframes lui-skeleton-pulse"

      assert css =~
               ~r/@media \(prefers-reduced-motion: reduce\) \{\s*\.lui-skeleton \{\s*animation: none;/
    end

    test "bundled CSS styles the text and circle variants" do
      css = File.read!("priv/static/lantern_ui.css")

      assert css =~ ~s(.lui-skeleton[data-variant="text"])
      assert css =~ ~s(.lui-skeleton[data-variant="circle"])
    end

    test "bundled CSS gives the status wrapper a neutral display (not display: contents)" do
      css = File.read!("priv/static/lantern_ui.css")

      assert css =~ ~r/\.lui-skeleton-status \{\s*display: block;/
      refute css =~ ~r/\.lui-skeleton-status \{\s*display: contents/
    end

    test "registry and only importer expose skeleton/1" do
      assert LanternUI.__components__()[:skeleton] == Skeleton

      [{module, _bytecode}] =
        Code.compile_string("""
        defmodule SkeletonOnlyImport do
          use LanternUI, only: [:skeleton]
          def render(assigns), do: skeleton(assigns)
        end
        """)

      assert function_exported?(module, :render, 1)
    end
  end
end
