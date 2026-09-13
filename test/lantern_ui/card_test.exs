defmodule LanternUI.CardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Card
  alias LanternUI.Components.DescriptionList

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "card/1" do
    test "renders title, description and body" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card title="Participants" description="Everyone on this settlement.">
            body text
          </Card.card>
          """
        end)

      assert html =~ ~s(class="lui-card")
      assert html =~ ~s(class="lui-card-title")
      assert html =~ "Participants"
      assert html =~ "Everyone on this settlement."
      assert html =~ "body text"
    end

    test "omits the head entirely when there is nothing to put in it" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card>just a panel</Card.card>
          """
        end)

      refute html =~ "lui-card-head"
      assert html =~ "just a panel"
    end

    test "an actions slot alone is enough to draw the head" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card>
            <:actions>btn</:actions>
            body
          </Card.card>
          """
        end)

      assert html =~ "lui-card-head"
      assert html =~ ~s(class="lui-card-actions")
    end

    test "flush drops the body padding" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card flush>table</Card.card>
          """
        end)

      assert html =~ "lui-card-body-flush"
    end

    test "a header slot replaces the title block" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card title="Ignored">
            <:header><span>custom</span></:header>
            body
          </Card.card>
          """
        end)

      assert html =~ "custom"
      refute html =~ "Ignored"
    end

    test "a hero-* icon is rendered as a mask span carrying the host class" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card title="Users" icon="hero-users">body</Card.card>
          """
        end)

      assert html =~ "lui-card-icon-mask"
      assert html =~ "hero-users"
    end

    test "footer renders below the body" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card title="T">
            body
            <:footer>3 of 4 responded</:footer>
          </Card.card>
          """
        end)

      assert html =~ ~s(class="lui-card-foot")
      assert html =~ "3 of 4 responded"
    end
  end

  describe "card_grid/1" do
    test "passes the flex basis through as a custom property" do
      html =
        render(fn assigns ->
          ~H"""
          <Card.card_grid min="20rem">
            <Card.card>a</Card.card>
          </Card.card_grid>
          """
        end)

      assert html =~ ~s(class="lui-card-grid")
      assert html =~ "--lui-card-min: 20rem"
    end
  end

  describe "description_list/1" do
    test "renders each pair as a label and value" do
      html =
        render(fn assigns ->
          ~H"""
          <DescriptionList.description_list>
            <:item label="Created">Jan 4</:item>
            <:item label="Host">Alex</:item>
          </DescriptionList.description_list>
          """
        end)

      assert html =~ ~s(class="lui-dl-label")
      assert html =~ "Created"
      assert html =~ "Jan 4"
      assert html =~ "Host"
      assert html =~ "Alex"
    end

    test "defaults to two stacked columns" do
      html =
        render(fn assigns ->
          ~H"""
          <DescriptionList.description_list>
            <:item label="A">1</:item>
          </DescriptionList.description_list>
          """
        end)

      assert html =~ "lui-dl-cols-2"
      assert html =~ "lui-dl-stacked"
    end

    test "layout and columns are reflected as classes" do
      html =
        render(fn assigns ->
          ~H"""
          <DescriptionList.description_list layout="inline" columns={1}>
            <:item label="A">1</:item>
          </DescriptionList.description_list>
          """
        end)

      assert html =~ "lui-dl-inline"
      assert html =~ "lui-dl-cols-1"
    end

    test "a wide item spans every column" do
      html =
        render(fn assigns ->
          ~H"""
          <DescriptionList.description_list>
            <:item label="Notes" wide>long text</:item>
          </DescriptionList.description_list>
          """
        end)

      assert html =~ "lui-dl-wide"
    end
  end
end
