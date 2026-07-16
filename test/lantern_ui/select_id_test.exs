defmodule LanternUI.SelectIdTest do
  @moduledoc """
  The `select/1` DOM id contract (flicker #929).

  Precedence is `explicit id > field.id > per-path fallback`. The two paths take
  opposite fallbacks on a bare `name=`, because they need opposite things: the
  rich path's id drives a `phx-hook` (must stay stable across patches), the
  native path's id only wires `<label for>` (must be unique).
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Select

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp ids(html), do: Regex.scan(~r/id="([^"]+)"/, html) |> Enum.map(&List.last/1)

  describe "native path — bare name auto-generates (Fluxon drop-in parity)" do
    test "auto-generates an id when neither id nor field is given" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native name="payment_policy_id" options={["a", "b"]} />
          """
        end)

      assert html =~ ~r/id="lui-select-\d+"/
      refute html =~ ~s(id="payment_policy_id")
    end

    test "same name rendered twice yields DIFFERENT ids (the #929 regression)" do
      # Mirrors enventory_new's eBay policy selects: one panel per product type,
      # each with a bare name= and no id. Name-derivation collided here.
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native name="payment_policy_id" options={["a"]} />
          <Select.select native name="payment_policy_id" options={["a"]} />
          """
        end)

      generated = Enum.filter(ids(html), &String.starts_with?(&1, "lui-select-"))

      assert length(generated) == 2
      assert Enum.uniq(generated) == generated, "duplicate DOM ids: #{inspect(generated)}"
    end

    test "no duplicate ids anywhere in the rendered document" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native name="p" label="One" options={["a"]} />
          <Select.select native name="p" label="Two" options={["a"]} />
          """
        end)

      all = ids(html)
      assert Enum.uniq(all) == all, "duplicate DOM ids: #{inspect(all -- Enum.uniq(all))}"
    end

    test "label association survives generation — <label for> matches the select id" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native name="payment_policy_id" label="Payment policy" options={["a"]} />
          """
        end)

      [id] = Regex.run(~r/<select\s+id="([^"]+)"/, html, capture: :all_but_first)
      assert html =~ ~s(for="#{id}")
    end

    test "error id wiring follows the generated id" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native name="p" options={["a"]} errors={["is invalid"]} />
          """
        end)

      [id] = Regex.run(~r/<select\s+id="([^"]+)"/, html, capture: :all_but_first)
      assert html =~ ~s(id="#{id}-error")
    end
  end

  describe "native path — explicit id / field still win (stability escape hatch)" do
    test "an explicit id is used verbatim and never generated over" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select native id="policy-42" name="payment_policy_id" options={["a"]} />
          """
        end)

      assert html =~ ~s(id="policy-42")
      refute html =~ ~r/id="lui-select-\d+"/
    end

    test "a field supplies the stable, form-scoped id — generation does not apply" do
      form = Phoenix.Component.to_form(%{"status" => "active"}, as: :thing)

      html =
        render(
          fn assigns ->
            ~H"""
            <Select.select native field={@form[:status]} label="Status" options={["active"]} />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(id="thing_status")
      assert html =~ ~s(for="thing_status")
      refute html =~ ~r/id="lui-select-\d+"/
    end
  end

  describe "rich path — id stays name-derived (hook stability, Fluxon parity)" do
    test "bare name derives the id from name so the hook id stays stable" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select name="status" options={["a"]} />
          """
        end)

      assert html =~ ~s(id="status")
      assert html =~ ~s(id="status-select")
      assert html =~ ~s(phx-hook="LanternSelect")
      refute html =~ ~r/id="lui-select-\d+"/
    end

    test "a field supplies the id" do
      form = Phoenix.Component.to_form(%{"status" => "active"}, as: :thing)

      html =
        render(
          fn assigns ->
            ~H"""
            <Select.select field={@form[:status]} options={["active"]} />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(id="thing_status")
      assert html =~ ~s(id="thing_status-select")
    end
  end
end
