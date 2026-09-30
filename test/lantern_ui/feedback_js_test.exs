defmodule LanternUI.FeedbackJSTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "tooltip/1" do
    test "renders trigger, panel, role, and data attributes" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Tooltip.tooltip
            id="tip-save"
            value="Save the object"
            placement="bottom"
            delay={125}
          >
            Save
          </LanternUI.Components.Tooltip.tooltip>
          """
        end)

      assert html =~ ~s(id="tip-save")
      assert html =~ ~s(class="lui-tooltip-wrap")
      assert html =~ ~s(phx-hook="LanternTooltip")
      assert html =~ ~s(data-placement="bottom")
      assert html =~ ~s(data-delay="125")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(class="lui-tooltip-trigger")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~s(role="tooltip")
      assert html =~ ~s(hidden)
      assert html =~ "Save"
      assert html =~ "Save the object"
      assert html =~ "lui-tooltip-arrow"
    end

    test "auto-generates an id when omitted (Fluxon drop-in parity)" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Tooltip.tooltip value="No id given">
            Hover
          </LanternUI.Components.Tooltip.tooltip>
          """
        end)

      assert html =~ ~r/id="lui-tooltip-\d+"/
      assert html =~ ~s(phx-hook="LanternTooltip")
    end

    test "content slot wins over value" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Tooltip.tooltip id="tip-rich" value="Plain fallback">
            Hover
            <:content><strong>Rich content</strong></:content>
          </LanternUI.Components.Tooltip.tooltip>
          """
        end)

      assert html =~ "Rich content"
      refute html =~ "Plain fallback"
    end

    test "arrow can be disabled" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Tooltip.tooltip id="tip-no-arrow" value="No arrow" arrow={false}>
            Hover
          </LanternUI.Components.Tooltip.tooltip>
          """
        end)

      refute html =~ "lui-tooltip-arrow"
    end
  end

  describe "toast_group/1" do
    test "renders hook, aria-live, and placement" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Toast.toast_group id="alerts" placement="bottom-right" />
          """
        end)

      assert html =~ ~s(id="alerts")
      assert html =~ ~s(class="lui-toasts")
      assert html =~ ~s(phx-hook="LanternToast")
      assert html =~ ~s(data-part="client")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ ~s(data-part="flashes")
      assert html =~ ~s(data-placement="bottom-right")
      assert html =~ ~s(aria-live="polite")
    end

    test "accepts every corner and edge-center placement" do
      for placement <- ~w(top-left top-center top-right bottom-left bottom-center bottom-right) do
        html =
          render(fn assigns ->
            assigns = Map.put(assigns, :placement, placement)

            ~H"""
            <LanternUI.Components.Toast.toast_group id="t" placement={@placement} />
            """
          end)

        assert html =~ ~s(data-placement="#{placement}")
      end
    end

    test "sets the deck cap and renders info/error flashes with clear events" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Toast.toast_group
            id="alerts"
            max={12}
            flash={%{info: "Saved", error: "Failed"}}
          />
          """
        end)

      assert html =~ ~s(data-max="10")
      assert html =~ ~s(data-kind="info")
      assert html =~ ~s(data-kind="error")
      assert html =~ "Saved"
      assert html =~ "Failed"
      assert html =~ ~s(phx-click="lv:clear-flash")
      assert html =~ ~s(phx-value-key="info")
      assert html =~ ~s(phx-value-key="error")
    end
  end

  describe "send_toast/4 duration" do
    test "only a nonnegative integer duration is accepted" do
      for {duration, expected} <- [
            {0, 0},
            {750, 750},
            {false, 4000},
            {nil, 4000},
            {750.5, 4000},
            {"0", 4000},
            {-1, 4000}
          ] do
        socket = %Phoenix.LiveView.Socket{private: %{live_temp: %{}}}
        updated = LanternUI.send_toast(socket, :info, "Message", duration: duration)
        assert [["lantern:toast", %{duration: ^expected}]] = updated.private.live_temp.push_events
      end
    end
  end

  describe "theme/1" do
    import Phoenix.Component

    test "renders the LanternTheme mount point" do
      assigns = %{__changed__: nil}

      html =
        rendered_to_string(~H"""
        <LanternUI.Components.Theme.theme />
        """)

      assert html =~ ~s(phx-hook="LanternTheme")
      assert html =~ ~s(data-storage-key="lui-theme")
      assert html =~ "hidden"
    end
  end
end
