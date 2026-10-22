defmodule LanternUI.ShadcnAppPresetTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias LanternUI.Components.Layout

  @theme File.read!(Path.expand("../../priv/static/lantern_ui_theme.css", __DIR__))

  # Contract gate: component markup sizes text through the `--lantern-text*`
  # scale, so a preset (or a host) can retune it. An inline literal bypasses it.
  test "lantern component markup has no arbitrary text sizes" do
    offenders =
      Path.expand("../../lib", __DIR__)
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.reject(&String.ends_with?(&1, "/llms.ex"))
      |> Enum.flat_map(fn file ->
        file
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _} ->
          line =~ ~r/text-\[|font-size:\s*[\d.]|(?<![\w-])text-(xs|sm|base|lg|xl)\b/
        end)
        |> Enum.map(fn {line, n} ->
          "#{Path.relative_to_cwd(file)}:#{n}: #{String.trim(line)}"
        end)
      end)

    assert offenders == []
  end

  test "app preset sets the measured values through tokens" do
    [_, preset] = String.split(@theme, "app preset (opt-in", parts: 2)

    for decl <- [
          "--lantern-text: 0.964286rem",
          "--lui-table-leading: 1.5",
          "--lui-table-cell-px: 1rem",
          "--lui-table-cell-py: 0.5rem",
          "--lui-table-shadow: none",
          "--radius: 0.5rem",
          "--primary: oklch(0.556 0.176 36)",
          "--primary: oklch(0.685 0.182 39)",
          "--lui-sidebar-expanded-w: 16rem",
          "--lui-topline-h: 3rem"
        ] do
      assert preset =~ decl
    end
  end

  test "page_shell bare layout renders no trail row" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Layout.page_shell id="projects" layout="bare" title="Projects">
        BODY
      </Layout.page_shell>
      """)

    assert html =~ ~s(data-page-layout="bare")
    assert html =~ ~s(data-page-title)
    assert html =~ "BODY"
    refute html =~ "lui-page-topline"
    refute html =~ "lui-breadcrumb"
  end
end
