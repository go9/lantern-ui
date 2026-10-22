defmodule LanternUI.PageRecipesTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  use LanternUI

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()
  defp parse(html), do: Floki.parse_fragment!(html)

  test "page_container carries a named width and the heading is an h2 with one action region" do
    html =
      render(fn assigns ->
        ~H"""
        <.page_container width="narrow">
          <.page_heading title="Projects" lead="All of them.">
            <:actions><button>New</button></:actions>
          </.page_heading>
        </.page_container>
        """
      end)

    doc = parse(html)
    assert [{_, attrs, _}] = Floki.find(doc, ".lui-page-container")
    assert {"data-page-width", "narrow"} in attrs
    assert Floki.find(doc, "h2.lui-page-heading-title") |> Floki.text() == "Projects"
    assert Floki.find(doc, "h1") == []
    assert length(Floki.find(doc, ".lui-page-heading-actions")) == 1
  end

  test "index_toolbar renders only the regions it is given, actions last" do
    html =
      render(fn assigns ->
        ~H"""
        <.index_toolbar>
          <:search><input type="search" /></:search>
          <:filters><button>Filters</button></:filters>
        </.index_toolbar>
        """
      end)

    doc = parse(html)
    assert length(Floki.find(doc, ".lui-index-toolbar-search")) == 1
    assert length(Floki.find(doc, ".lui-index-toolbar-filters")) == 1
    assert Floki.find(doc, ".lui-index-toolbar-views") == []
    assert Floki.find(doc, ".lui-index-toolbar-actions") == []
  end

  test "detail_layout adds the rail class and aside only when a rail is given" do
    with_rail =
      render(fn assigns ->
        ~H"""
        <.detail_layout>
          <.page_section id="a" title="A">body</.page_section>
          <:rail>props</:rail>
        </.detail_layout>
        """
      end)
      |> parse()

    assert length(Floki.find(with_rail, ".lui-detail-layout-rail aside.lui-detail-rail")) == 1
    assert Floki.find(with_rail, "section#a[aria-labelledby=a-title] h3") |> Floki.text() == "A"

    no_rail =
      render(fn assigns ->
        ~H"""
        <.detail_layout>x</.detail_layout>
        """
      end)
      |> parse()

    assert Floki.find(no_rail, "aside") == []
    assert Floki.find(no_rail, ".lui-detail-layout-rail") == []
  end

  describe "settings_form" do
    defp settings(dirty) do
      render(fn assigns ->
        assigns = assign(assigns, dirty: dirty, form: to_form(%{"name" => "Atlas"}, as: :p))

        ~H"""
        <.settings_page layout="stacked" title="Settings">
          <.settings_form for={@form} dirty={@dirty} title="Project" phx-submit="save">
            <.input field={@form[:name]} label="Name" />
            <:actions><button type="button">Cancel</button></:actions>
          </.settings_form>
        </.settings_page>
        """
      end)
      |> parse()
    end

    test "has exactly one submit and it is disabled while clean" do
      doc = settings(false)
      assert [{_, attrs, _}] = Floki.find(doc, "form button[type=submit]")
      assert Enum.any?(attrs, &match?({"disabled", _}, &1))
      assert Floki.find(doc, ".lui-settings-dirty") |> Floki.text() == ""
      assert [{_, attrs, _}] = Floki.find(doc, ".lui-settings-page")
      assert {"data-layout", "stacked"} in attrs
    end

    test "enables Save and says so when dirty" do
      doc = settings(true)
      assert [{_, attrs, _}] = Floki.find(doc, "form button[type=submit]")
      refute Enum.any?(attrs, &match?({"disabled", _}, &1))
      assert Floki.find(doc, ".lui-settings-dirty") |> Floki.text() == "Unsaved changes"
    end

    test "renders no tablist and no nav unless asked" do
      doc = settings(false)
      assert Floki.find(doc, "[role=tablist]") == []
      assert Floki.find(doc, "nav.lui-settings-nav") == []
    end
  end

  test "settings_page nav marks the active link with aria-current" do
    doc =
      render(fn assigns ->
        ~H"""
        <.settings_page layout="stacked" title="Settings">
          <:nav navigate="/a" active>General</:nav>
          <:nav navigate="/b">Keys</:nav>
          body
        </.settings_page>
        """
      end)
      |> parse()

    assert [_] = Floki.find(doc, "nav.lui-settings-nav[aria-label]")
    assert [_] = Floki.find(doc, "a.lui-settings-nav-item[aria-current=page]")
    assert length(Floki.find(doc, "a.lui-settings-nav-item")) == 2
  end

  test "form_group and form_actions" do
    doc =
      render(fn assigns ->
        ~H"""
        <.form_group legend="Project" description="Shown everywhere." columns={2}>
          <.input id="a" name="a" label="A" />
        </.form_group>
        <.form_actions><button>Save</button></.form_actions>
        """
      end)
      |> parse()

    assert Floki.find(doc, "fieldset.lui-form-group[data-columns=2] legend") |> Floki.text() ==
             "Project"

    assert length(Floki.find(doc, ".lui-form-actions")) == 1
  end

  describe "empty_state kind" do
    defp empty(kind) do
      render(fn assigns ->
        assigns = assign(assigns, kind: kind)

        ~H"""
        <.empty_state kind={@kind} title="T">
          One sentence.<:action><button>Go</button></:action>
        </.empty_state>
        """
      end)
      |> parse()
    end

    test "each kind supplies a default icon and data-kind" do
      for kind <- ~w(first_use no_match error restricted) do
        doc = empty(kind)

        assert [_] =
                 Floki.find(
                   doc,
                   ".lui-empty[data-kind=#{kind}] svg.lui-empty-icon, .lui-empty[data-kind=#{kind}] .lui-empty-icon"
                 )
      end
    end

    test "only error is an alert" do
      assert [_] = Floki.find(empty("error"), ".lui-empty[role=alert]")
      assert Floki.find(empty("no_match"), "[role=alert]") == []
    end
  end

  test "recipes are documented and the skill points at them" do
    docs = File.read!("docs/page-recipes.md")
    skill = File.read!("skills/lantern-recipes/SKILL.md")
    assert skill =~ "docs/page-recipes.md"

    for name <-
          ~w(page_container page_heading page_section index_toolbar detail_layout settings_page settings_form form_group form_actions empty_state) do
      assert docs =~ name, "#{name} missing from docs/page-recipes.md"
    end
  end
end
