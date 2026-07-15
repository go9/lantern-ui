defmodule LanternUI.Components806Test do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Breadcrumb
  alias LanternUI.Components.Checkbox
  alias LanternUI.Components.Dropdown
  alias LanternUI.Components.EmptyState
  alias LanternUI.Components.Modal

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "checkbox/1" do
    test "renders checkbox + hidden unchecked input + label" do
      html =
        render(fn assigns ->
          ~H"""
          <Checkbox.checkbox id="c" name="notify" checked label="Email me" description="Daily max." />
          """
        end)

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(type="hidden" name="notify" value="false")
      assert html =~ ~s(checked)
      assert html =~ "Email me"
      assert html =~ "Daily max."
    end

    test "FormField clause derives id/name and checked from the value" do
      form = Phoenix.Component.to_form(%{"accept" => "true"}, as: :thing)

      html =
        render(
          fn assigns ->
            ~H"""
            <Checkbox.checkbox field={@form[:accept]} label="Accept" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="thing[accept]")
      assert html =~ ~s(id="thing_accept")
      assert html =~ "checked"
    end

    test "custom checked/unchecked values submit correctly" do
      html =
        render(fn assigns ->
          ~H"""
          <Checkbox.checkbox name="state" value="on" checked_value="on" unchecked_value="off" />
          """
        end)

      assert html =~ ~s(type="hidden" name="state" value="off")
      assert html =~ ~s(value="on")
      assert html =~ "checked"
    end

    test "errors render with aria wiring" do
      html =
        render(fn assigns ->
          ~H"""
          <Checkbox.checkbox id="c" name="x" errors={["must be accepted"]} label="Terms" />
          """
        end)

      assert html =~ "must be accepted"
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "modal/1" do
    test "renders hidden dialog with hook, backdrop, panel, close button" do
      html =
        render(fn assigns ->
          ~H"""
          <Modal.modal id="m1">Hello</Modal.modal>
          """
        end)

      assert html =~ ~s(phx-hook="LanternModal")
      assert html =~ ~s(hidden)
      assert html =~ ~s(data-part="backdrop")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(data-part="close")
      assert html =~ "Hello"
    end

    test "open renders unhidden; prevent_closing drops close button and dismissals" do
      html =
        render(fn assigns ->
          ~H"""
          <Modal.modal id="m2" open prevent_closing>Locked</Modal.modal>
          """
        end)

      refute html =~ ~s(<div\n  id="m2"\n  hidden)
      assert html =~ ~s(data-open)
      assert html =~ ~s(data-close-on-esc="false")
      assert html =~ ~s(data-close-on-outside="false")
      refute html =~ ~s(data-part="close")
    end

    test "open_dialog/close_dialog produce JS dispatch commands" do
      assert %Phoenix.LiveView.JS{ops: ops} = LanternUI.open_dialog("m1")
      assert inspect(ops) =~ "lantern:dialog:open"
      assert %Phoenix.LiveView.JS{ops: ops2} = LanternUI.close_dialog("m1")
      assert inspect(ops2) =~ "lantern:dialog:close"
    end

    test "component CSS respects the hidden attribute (regression: modal must hide when closed)" do
      # `.lui-modal { display: flex }` overrides the UA `[hidden]{display:none}`,
      # so without an explicit `.lui-modal[hidden]{display:none}` the modal is
      # always visible ("auto-opens", can't be closed).
      css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))
      assert css =~ ".lui-modal[hidden]"
    end
  end

  describe "dropdown/1" do
    test "renders trigger + hidden menu with items, separator, header" do
      html =
        render(fn assigns ->
          ~H"""
          <Dropdown.dropdown id="dd" label="Actions">
            <Dropdown.dropdown_header>file.png</Dropdown.dropdown_header>
            <Dropdown.dropdown_button phx-click="download">Download</Dropdown.dropdown_button>
            <Dropdown.dropdown_separator />
            <Dropdown.dropdown_link navigate="/x">Open</Dropdown.dropdown_link>
          </Dropdown.dropdown>
          """
        end)

      assert html =~ ~s(phx-hook="LanternDropdown")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(role="menu")
      assert html =~ ~s(role="menuitem")
      assert html =~ ~s(role="separator")
      assert html =~ "file.png"
      assert html =~ "Download"
      assert html =~ ~s(href="/x")
      assert html =~ ~s(aria-haspopup="menu")
    end

    test "auto-generates an id when omitted (Fluxon drop-in parity)" do
      html =
        render(fn assigns ->
          ~H"""
          <Dropdown.dropdown label="Actions">
            <Dropdown.dropdown_button phx-click="go">Go</Dropdown.dropdown_button>
          </Dropdown.dropdown>
          """
        end)

      assert html =~ ~r/id="lui-dropdown-\d+"/
      assert html =~ ~s(phx-hook="LanternDropdown")
    end

    test "custom toggle slot replaces the default button" do
      html =
        render(fn assigns ->
          ~H"""
          <Dropdown.dropdown id="dd2">
            <:toggle><button class="custom-t">…</button></:toggle>
            <Dropdown.dropdown_button>One</Dropdown.dropdown_button>
          </Dropdown.dropdown>
          """
        end)

      assert html =~ "custom-t"
      refute html =~ "lui-btn"
    end
  end

  describe "breadcrumb/1" do
    test "renders links, buttons, current, and separators" do
      html =
        render(fn assigns ->
          ~H"""
          <Breadcrumb.breadcrumb>
            <:item navigate="/b">bucket</:item>
            <:item phx-click="navigate" phx-value-prefix="a/">a</:item>
            <:item current>2026</:item>
          </Breadcrumb.breadcrumb>
          """
        end)

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(href="/b")
      assert html =~ ~s(phx-click="navigate")
      assert html =~ ~s(phx-value-prefix="a/")
      assert html =~ ~s(aria-current="page")
      assert html =~ "lui-breadcrumb-sep"
    end
  end

  describe "empty_state/1" do
    test "renders icon, title, description, actions" do
      html =
        render(fn assigns ->
          ~H"""
          <EmptyState.empty_state icon="folder-open" title="No objects">
            Drop files anywhere.
            <:action><button>Upload</button></:action>
          </EmptyState.empty_state>
          """
        end)

      assert html =~ "lui-empty-icon"
      assert html =~ "No objects"
      assert html =~ "Drop files anywhere."
      assert html =~ "Upload"
    end
  end

  describe "use LanternUI registry" do
    test "new component groups are importable" do
      keys = Map.keys(LanternUI.__components__())

      for k <- [:checkbox, :modal, :dropdown, :breadcrumb, :empty_state, :tooltip, :toast] do
        assert k in keys
      end
    end
  end
end
