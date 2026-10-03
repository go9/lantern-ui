defmodule LanternUI.LlmsTest do
  use ExUnit.Case, async: true

  alias LanternUI.Llms

  test "catalog covers every public component with a use-when line" do
    modules = Llms.catalog()

    names =
      for %{components: components} <- modules,
          %{name: name, doc: doc} <- components,
          do: {name, doc}

    assert length(names) > 50
    assert Enum.all?(names, fn {_name, doc} -> doc != "" end)

    by_name = Map.new(names)
    assert by_name["stat_card"] =~ "metric"
    assert by_name["toast_group"] =~ "Toast"
    assert by_name["data_table"] != ""
  end

  test "recipes extract real HEEx from docs and README" do
    recipes = Llms.recipes()
    assert length(recipes) > 5

    assert Enum.any?(recipes, fn %{source: source, code: code} ->
             source == "docs/recipes.md" and code =~ "<.data_table" and code =~ ":filter"
           end)
  end

  test "generated files mention banned patterns, starters, and deprecations" do
    %{short: short, full: full} = Llms.generate(File.cwd!())

    assert short =~ "stat_card"
    assert short =~ "toast_group"
    assert short =~ "<.data_table"
    assert short =~ "breadcrumb bar"

    assert full =~ "icon_button"
    assert full =~ "tabs_list"
    assert full =~ "values:"
    assert full =~ "does not exist"
  end

  test "checked-in llms.txt and llms-full.txt are fresh" do
    assert :ok = Llms.check(File.cwd!())
  end
end
