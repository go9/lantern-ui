defmodule LanternUI.SkeletonTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Skeleton

  defp render(fun) do
    fun.(%{__changed__: nil}) |> rendered_to_string()
  end

  describe "skeleton/1" do
    test "renders the visible default class with decorative semantics" do
      html =
        render(fn assigns ->
          ~H"""
          <Skeleton.skeleton />
          """
        end)

      assert html =~ ~s(class="lui-skeleton")
      assert html =~ ~s(aria-hidden="true")
      refute html =~ ~s(role="status")
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
