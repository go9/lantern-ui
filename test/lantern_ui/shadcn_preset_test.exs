defmodule LanternUI.ShadcnPresetTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Theme
  alias LanternUI.ShadcnGallery

  @theme_css File.read!("priv/static/lantern_ui_theme.css")
  @gallery_dir "test/fixtures/shadcn_gallery"
  @sections ~w(button input textarea select badge card alert table tabs separator)

  describe "shadcn preset scope" do
    test "defines the shadcn vocabulary, light + dark" do
      assert @theme_css =~ ~s([data-lantern-theme="shadcn"])
      assert @theme_css =~ "--background: oklch(1 0 0);"
      assert @theme_css =~ "--foreground: oklch(0.145 0 0);"
      assert @theme_css =~ "--radius: 0.625rem;"
      assert @theme_css =~ "--chart-1:"
      for index <- 1..6, do: assert(@theme_css =~ "--lantern-chart-#{index}:")
      assert @theme_css =~ "--sidebar:"
      assert @theme_css =~ ".dark[data-lantern-theme=\"shadcn\"]"
      assert @theme_css =~ "--background: oklch(0.145 0 0);"

      [_, dark_theme] = String.split(@theme_css, ".dark {", parts: 2)
      dark_rule = dark_theme |> String.split("}", parts: 2) |> hd()
      for index <- 1..6, do: assert(dark_rule =~ "--lantern-chart-#{index}:")
    end

    test "re-points lantern tokens and moves to h-9 proportions" do
      assert @theme_css =~ "--lantern-surface: var(--background);"
      assert @theme_css =~ "--lantern-primary: var(--primary);"
      assert @theme_css =~ "--lantern-danger: var(--destructive);"
      assert @theme_css =~ "--lantern-ring: var(--ring);"
      assert @theme_css =~ "--lantern-control-h: 2.25rem;"
    end

    test "opt-in only: the default :root rule keeps h-8 proportions" do
      [_, root_and_after] = String.split(@theme_css, ":root {", parts: 2)
      [root_rule | _] = String.split(root_and_after, "}")
      assert root_rule =~ "--lantern-control-h: 2rem;"
      refute root_rule =~ "--background: oklch(1 0 0);"
    end
  end

  describe "Theme theme/1 preset" do
    test "emits data-preset for the hook" do
      html =
        Theme.theme(%{
          __changed__: nil,
          id: "lantern-theme",
          storage_key: "lui-theme",
          preset: "shadcn"
        })
        |> rendered_to_string()

      assert html =~ ~s(data-preset="shadcn")
    end

    test "omits data-preset by default" do
      html =
        Theme.theme(%{
          __changed__: nil,
          id: "lantern-theme",
          storage_key: "lui-theme",
          preset: nil
        })
        |> rendered_to_string()

      refute html =~ "data-preset"
    end
  end

  describe "gallery baseline" do
    test "writes the four theme documents with all ten sections" do
      File.mkdir_p!(@gallery_dir)

      for {theme, dark, name} <- [
            {nil, false, "default-light.html"},
            {nil, true, "default-dark.html"},
            {"shadcn", false, "shadcn-light.html"},
            {"shadcn", true, "shadcn-dark.html"}
          ] do
        html =
          ShadcnGallery.document(%{__changed__: nil, theme: theme, dark: dark})
          |> rendered_to_string()

        for section <- @sections do
          assert html =~ ~s(data-gallery="#{section}"),
                 "missing #{section} in #{name}"
        end

        File.write!(Path.join(@gallery_dir, name), html)
      end
    end
  end
end
