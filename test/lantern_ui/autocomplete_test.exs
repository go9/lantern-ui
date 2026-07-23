defmodule LanternUI.AutocompleteTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Autocomplete

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "keeps static form semantics and selected label" do
    html =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete
          id="sku"
          name="sku"
          value="sku-2"
          options={[{"SKU One", "sku-1"}, {"SKU Two", "sku-2"}]}
        />
        """
      end)

    assert html =~ ~s(phx-hook="LanternAutocomplete")
    assert html =~ ~s(type="hidden" name="sku" value="sku-2")
    assert html =~ ~s(role="combobox")
    assert html =~ ~s(value="SKU Two")
    assert html =~ ~s(data-value="sku-2")
    assert html =~ ~s(aria-selected="true")
  end

  test "FormField derives id, name, value, and disabled state remains native" do
    form = Phoenix.Component.to_form(%{"status" => "active"}, as: :thing)

    html =
      render(
        fn assigns ->
          ~H"""
          <Autocomplete.autocomplete
            field={@form[:status]}
            options={[{"Active", "active"}]}
            disabled
          />
          """
        end,
        %{form: form}
      )

    assert html =~ ~s(id="thing_status-ac")
    assert html =~ ~s(name="thing[status]")
    assert html =~ ~s(value="active")

    document = Floki.parse_document!(html)

    assert [{"input", attrs, []}] =
             Floki.find(document, ~s(input[type="hidden"][name="thing[status]"]))

    assert {"disabled", "disabled"} in attrs
  end

  test "renders Fluxon-compatible async configuration and resolvable ARIA relationships" do
    html =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete
          id="user"
          name="user_id"
          options={[]}
          autofocus
          on_search="search_users"
          debounce={350}
          search_threshold={2}
          search_mode="starts-with"
          open_on_focus
          clearable
          animation="motion"
          animation_enter="enter"
          animation_leave="leave"
        />
        """
      end)

    assert html =~ ~s(data-server-search="search_users")
    assert html =~ ~s(data-debounce="350")
    assert html =~ ~s(data-search-threshold="2")
    assert html =~ ~s(data-search-mode="starts-with")
    assert html =~ ~s(data-open-on-focus="true")
    refute html =~ "motion"
    refute html =~ ~s(data-animation-enter)
    refute html =~ ~s(data-animation-leave)
    assert html =~ ~s(autofocus)
    assert html =~ ~s(data-part="clear")
    assert html =~ ~s(data-part="loading")
    assert html =~ ~s(aria-controls="user-listbox")
    assert html =~ ~s(id="user-listbox")
  end

  test "renders grouped rich options, all affixes, header, footer, and custom empty state" do
    html =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete
          id="place"
          name="place"
          options={[{"Europe", [{"France", [{"Paris", 1}]}]}, {"Asia", [{"Tokyo", 2}]}]}
        >
          <:outer_prefix class="op">Outside before</:outer_prefix>
          <:inner_prefix class="ip">Inside before</:inner_prefix>
          <:inner_suffix class="is">Inside after</:inner_suffix>
          <:outer_suffix class="os">Outside after</:outer_suffix>
          <:header class="head">Suggested places</:header>
          <:option :let={{label, value}} class="rich">{label} ({value})</:option>
          <:empty_state class="empty">Nothing here</:empty_state>
          <:footer class="foot">Keep typing</:footer>
        </Autocomplete.autocomplete>
        """
      end)

    assert html =~ ~s(data-part="group")
    assert html =~ "Europe"
    assert html =~ "France"
    assert html =~ "Paris (1)"
    for marker <- ~w(op ip is os head rich empty foot), do: assert(html =~ marker)
    assert html =~ "Nothing here"
    assert html =~ ~s(data-default-text="false")
  end

  test "restores the existing static placeholder and empty-state defaults" do
    html =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete id="empty" name="empty" options={[]} />
        """
      end)

    assert html =~ ~s(placeholder="Search…")
    assert html =~ ~s(data-empty-template="No results")
    assert html =~ ~s(data-default-text="true")

    assert Floki.find(Floki.parse_document!(html), ~s([data-part="no-results"])) |> Floki.text() =~
             "No results"
  end

  test "preserves list-valued tuples and offers an explicit unambiguous group form" do
    list_value =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete id="scope" name="scope" options={[{"Scopes", ["read", "write"]}]} />
        """
      end)

    assert Floki.find(Floki.parse_document!(list_value), ~s([data-part="group"])) == []
    assert length(Floki.find(Floki.parse_document!(list_value), ~s([data-part="option"]))) == 1

    explicit_group =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete
          id="scope-group"
          name="scope-group"
          options={[{:group, "Scopes", ["read", "write"]}]}
        />
        """
      end)

    assert length(Floki.find(Floki.parse_document!(explicit_group), ~s([data-part="group"]))) == 1

    assert length(Floki.find(Floki.parse_document!(explicit_group), ~s([data-part="option"]))) ==
             2
  end
end
