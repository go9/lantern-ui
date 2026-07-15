defmodule LanternUI.AutocompleteTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Autocomplete

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "renders hook, hidden value, combobox input, options, and no-results element" do
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
    assert html =~ ~s(aria-autocomplete="list")
    assert html =~ ~s(data-part="option")
    assert html =~ ~s(data-value="sku-1")
    assert html =~ ~s(data-part="no-results")
    assert html =~ "No results"
  end

  test "FormField clause extracts name and value" do
    form = Phoenix.Component.to_form(%{"status" => "active"}, as: :thing)

    html =
      render(
        fn assigns ->
          ~H"""
          <Autocomplete.autocomplete field={@form[:status]} options={[{"Active", "active"}]} />
          """
        end,
        %{form: form}
      )

    assert html =~ ~s(id="thing_status-ac")
    assert html =~ ~s(name="thing[status]")
    assert html =~ ~s(value="active")
  end

  test "selected value prefills the input label" do
    html =
      render(fn assigns ->
        ~H"""
        <Autocomplete.autocomplete
          id="channel"
          name="channel"
          value="shopify"
          options={[{"eBay", "ebay"}, {"Shopify", "shopify"}]}
        />
        """
      end)

    assert html =~ ~s(class="lui-autocomplete-input")
    assert html =~ ~s(value="Shopify")
    assert html =~ ~s(data-value="shopify")
    assert html =~ ~s(aria-selected="true")
  end
end
