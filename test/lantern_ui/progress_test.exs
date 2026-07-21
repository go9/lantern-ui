defmodule LanternUI.ProgressTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Progress

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "progress/1" do
    test "determinate value sets aria-valuenow, fill width, size and color data attrs" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress value={40} />
          """
        end)

      assert html =~ ~s(class="lui-progress")
      assert html =~ ~s(role="progressbar")
      assert html =~ ~s(data-state="determinate")
      assert html =~ ~s(aria-valuenow="40")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(style="width: 40%")
      assert html =~ ~s(data-size="md")
      assert html =~ ~s(data-color="accent")
      assert html =~ ~s(aria-label="Progress")
      assert html =~ "lui-progress-fill"
    end

    test "nil value is indeterminate and omits aria-valuenow" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress value={nil} />
          """
        end)

      assert html =~ ~s(data-state="indeterminate")
      refute html =~ "aria-valuenow"
    end

    test "indeterminate attr forces indeterminate state" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress value={50} indeterminate />
          """
        end)

      assert html =~ ~s(data-state="indeterminate")
      refute html =~ "aria-valuenow"
    end

    test "default with no value is indeterminate" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress />
          """
        end)

      assert html =~ ~s(data-state="indeterminate")
      refute html =~ "aria-valuenow"
    end

    test "size color shimmer and label reflected as data attrs and aria-label" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress value={72} size="lg" color="success" shimmer label="Uploading" />
          """
        end)

      assert html =~ ~s(data-size="lg")
      assert html =~ ~s(data-color="success")
      assert html =~ ~s(data-shimmer="true")
      assert html =~ ~s(aria-label="Uploading")
      assert html =~ ~s(data-state="determinate")
      assert html =~ ~s(aria-valuenow="72")
    end

    test "shimmer is not set when indeterminate" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress indeterminate shimmer />
          """
        end)

      assert html =~ ~s(data-state="indeterminate")
      refute html =~ ~s(data-shimmer="true")
    end

    test "ARIA gate: progressbar with label is conformant" do
      html =
        render(fn assigns ->
          ~H"""
          <Progress.progress value={50} label="Uploading" />
          """
        end)

      assert ARIAConformance.audit(html, []) == []
    end
  end
end
