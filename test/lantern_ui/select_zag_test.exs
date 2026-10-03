defmodule LanternUI.SelectZagTest do
  @moduledoc """
  The Zag-driven select prototype (flicker #3416, step 1).

  The non-searchable rich path renders Zag anatomy (`data-scope="select"` +
  `data-part`) under the unchanged public attrs and `lui-*` styling, with
  `data-zag` marking roots the `LanternSelect` hook lazily upgrades to a
  `@zag-js/select` machine. Searchable and native paths are untouched.
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Select

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp zag_root(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-zag]")
    |> List.first()
  end

  defp html_attr(node, name) do
    node |> Floki.attribute(name) |> List.first()
  end

  describe "zag path (default rich, non-searchable)" do
    test "marks the hook root and keeps the public hook name" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" options={["a", "b"]} />
          """
        end)

      root = zag_root(html)
      assert root != nil
      assert html_attr(root, "phx-hook") == "LanternSelect"
      assert html_attr(root, "id") == "status-select"
    end

    test "renders zag anatomy with lui styling" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" options={[{"Active", "active"}]} />
          """
        end)

      doc = Floki.parse_document!(html)
      assert Floki.find(doc, ~s([data-scope="select"][data-part="root"])) != []
      assert Floki.find(doc, ~s([data-scope="select"][data-part="control"])) != []
      assert Floki.find(doc, ~s([data-scope="select"][data-part="positioner"])) != []
      assert Floki.find(doc, ~s([data-scope="select"][data-part="content"])) != []
      assert Floki.find(doc, ~s([data-scope="select"][data-part="hidden-select"])) != []
      assert Floki.find(doc, ~s([data-scope="select"][data-part="item-indicator"])) != []

      # Styling contract unchanged: the same lui-* classes as the legacy path.
      assert Floki.find(doc, "button.lui-select-toggle") != []
      assert Floki.find(doc, ".lui-select-listbox") != []
      assert Floki.find(doc, "button.lui-select-option") != []
    end

    test "trigger keeps the stable id and the label points at it" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" label="Status" options={["a"]} />
          """
        end)

      doc = Floki.parse_document!(html)
      assert Floki.find(doc, ~s(button#status[data-part="trigger"])) != []
      assert Floki.find(doc, ~s(label[for="status"])) != []

      root = zag_root(html)
      assert html_attr(root, "data-trigger-id") == "status"
    end

    test "items carry deterministic zag ids" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" options={[{"Active", "active"}]} />
          """
        end)

      doc = Floki.parse_document!(html)

      assert Floki.find(doc, ~s(#select\\:status-select\\:option\\:active)) != [] or
               html =~ ~s(id="select:status-select:option:active")
    end

    test "client mode serializes items and the default value, with no data-value" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select
            id="status"
            name="status"
            value="active"
            options={[{"Active", "active"}, {"Archived", "archived"}]}
          />
          """
        end)

      root = zag_root(html)

      assert Jason.decode!(html_attr(root, "data-items")) == [
               %{"value" => "active", "label" => "Active"},
               %{"value" => "archived", "label" => "Archived"}
             ]

      assert Jason.decode!(html_attr(root, "data-default-value")) == ["active"]
      assert html_attr(root, "data-value") == nil
      assert html_attr(root, "data-controlled") == nil
    end

    test "controlled mode serializes the server value and no default" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select
            id="status"
            name="status"
            controlled
            value="archived"
            options={["active", "archived"]}
            on_change="status_changed"
          />
          """
        end)

      root = zag_root(html)
      assert html_attr(root, "data-controlled") != nil
      assert Jason.decode!(html_attr(root, "data-value")) == ["archived"]
      assert html_attr(root, "data-default-value") == nil
      assert html_attr(root, "data-on-change") == "status_changed"
    end

    test "client mode without on_change emits no data-on-change" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" options={["a"]} />
          """
        end)

      assert html_attr(zag_root(html), "data-on-change") == nil
    end

    test "shields zag-written attributes from morphs" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" options={["a"]} />
          """
        end)

      root = zag_root(html)
      mounted = html_attr(root, "phx-mounted")
      assert mounted =~ "ignore_attrs"
      assert mounted =~ "data-scope"
      assert mounted =~ "aria-expanded"
      assert mounted =~ "aria-selected"
      assert mounted =~ "data-state"
      # Form state stays server-owned.
      refute mounted =~ "\"selected\""
      refute mounted =~ "aria-describedby"
    end

    test "hidden select keeps the form contract" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select
            id="status"
            name="status"
            value="active"
            options={[{"Active", "active"}, {"Archived", "archived"}]}
          />
          """
        end)

      doc = Floki.parse_document!(html)
      hidden = doc |> Floki.find("select[data-part='hidden-select']") |> List.first()
      assert Floki.attribute(hidden, "name") == ["status"]

      selected =
        doc
        |> Floki.find("select[data-part='hidden-select'] option[selected]")
        |> Enum.map(&Floki.attribute(&1, "value"))

      assert selected == [["active"]]
    end

    test "multiple submits name[] and clearable renders a clear trigger" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="tags" name="tags" multiple value={["a"]} clearable options={["a", "b"]} />
          """
        end)

      doc = Floki.parse_document!(html)
      hidden = doc |> Floki.find("select[data-part='hidden-select']") |> List.first()
      assert Floki.attribute(hidden, "name") == ["tags[]"]
      assert Floki.find(doc, ~s([data-part="clear-trigger"])) != []
    end
  end

  describe "untouched paths" do
    test "searchable stays on the legacy hook with no zag markup" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="status" name="status" searchable options={["a", "b"]} />
          """
        end)

      assert zag_root(html) == nil
      assert html =~ ~s(phx-hook="LanternSelect")
      assert html =~ ~s(data-part="toggle")
      assert html =~ ~s(data-part="search-input")
      refute html =~ "data-scope"
    end

    test "native stays hook-free with no zag markup" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select name="status" native options={["a", "b"]} />
          """
        end)

      assert zag_root(html) == nil
      refute html =~ "phx-hook"
      refute html =~ "data-scope"
    end
  end
end
