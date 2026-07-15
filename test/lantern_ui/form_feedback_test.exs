defmodule LanternUI.FormFeedbackTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Alert
  alias LanternUI.Components.Radio
  alias LanternUI.Components.Separator
  alias LanternUI.Components.Switch
  alias LanternUI.Components.Textarea

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "switch/1" do
    test "renders track, thumb, and label" do
      html =
        render(fn assigns ->
          ~H"""
          <Switch.switch id="s1" name="notify" checked label="Notifications" />
          """
        end)

      assert html =~ ~s(class="lui-switch")
      assert html =~ ~s(class="lui-switch-input")
      assert html =~ "lui-switch-track"
      assert html =~ "lui-switch-thumb"
      assert html =~ "Notifications"
      assert html =~ "checked"
    end

    test "FormField clause extracts name/value and renders hidden unchecked_value" do
      form = Phoenix.Component.to_form(%{"enabled" => "true"}, as: :prefs)

      html =
        render(
          fn assigns ->
            ~H"""
            <Switch.switch field={@form[:enabled]} label="Enabled" unchecked_value="off" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="prefs[enabled]")
      assert html =~ ~s(id="prefs_enabled")
      assert html =~ ~s(type="hidden" name="prefs[enabled]" value="off")
      assert html =~ "checked"
    end

    test "size and color data attrs" do
      html =
        render(fn assigns ->
          ~H"""
          <Switch.switch name="x" size="lg" color="danger" />
          """
        end)

      assert html =~ ~s(data-size="lg")
      assert html =~ ~s(data-color="danger")
    end
  end

  describe "radio/1" do
    test "renders radio group and marks matching option checked" do
      html =
        render(fn assigns ->
          ~H"""
          <Radio.radio name="plan" value="pro" label="Plan">
            <:radio value="basic" label="Basic" />
            <:radio value="pro" label="Pro" sublabel="Popular" />
          </Radio.radio>
          """
        end)

      assert html =~ ~s(class="lui-radio-group")
      assert html =~ ~s(data-variant="list")
      assert html =~ "Plan"
      assert html =~ "Basic"
      assert html =~ "Pro"
      assert html =~ "Popular"
      assert html =~ ~s(value="pro")
      # the pro option should be checked
      assert html =~ ~r/value="pro"[^>]*checked/
      refute html =~ ~r/value="basic"[^>]*checked/
    end

    test "FormField clause and cards variant" do
      form = Phoenix.Component.to_form(%{"tier" => "team"}, as: :acct)

      html =
        render(
          fn assigns ->
            ~H"""
            <Radio.radio field={@form[:tier]} variant="cards" label="Tier">
              <:radio value="free" label="Free" />
              <:radio value="team" label="Team" description="Collab" />
            </Radio.radio>
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="acct[tier]")
      assert html =~ ~s(data-variant="cards")
      assert html =~ ~r/value="team"[^>]*checked/
      assert html =~ "Collab"
    end
  end

  describe "textarea/1" do
    test "renders label and value" do
      html =
        render(fn assigns ->
          ~H"""
          <Textarea.textarea id="bio" name="bio" value="Hello" label="Bio" help_text="Short intro." />
          """
        end)

      assert html =~ "lui-textarea"
      assert html =~ "Bio"
      assert html =~ "Hello"
      assert html =~ "Short intro."
      refute html =~ "lui-error"
    end

    test "errors suppress help_text and set aria-invalid" do
      html =
        render(fn assigns ->
          ~H"""
          <Textarea.textarea
            id="notes"
            name="notes"
            value=""
            errors={["is required"]}
            help_text="optional hint"
          />
          """
        end)

      assert html =~ "is required"
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(data-invalid)
      refute html =~ "optional hint"
    end

    test "FormField clause extracts id/name/value" do
      form = Phoenix.Component.to_form(%{"body" => "draft"}, as: :post)

      html =
        render(
          fn assigns ->
            ~H"""
            <Textarea.textarea field={@form[:body]} label="Body" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="post[body]")
      assert html =~ ~s(id="post_body")
      assert html =~ "draft"
    end
  end

  describe "alert/1" do
    test "renders data-color, title, and body" do
      html =
        render(fn assigns ->
          ~H"""
          <Alert.alert id="a1" color="success" title="Saved" subtitle="Just now">
            All good.
          </Alert.alert>
          """
        end)

      assert html =~ ~s(role="alert")
      assert html =~ ~s(data-color="success")
      assert html =~ "Saved"
      assert html =~ "Just now"
      assert html =~ "All good."
      assert html =~ "lui-alert-title"
      # default hide_close=true → no close button
      refute html =~ "lui-alert-close"
    end

    test "close button only when hide_close is false" do
      html =
        render(fn assigns ->
          ~H"""
          <Alert.alert id="a2" title="Notice" hide_close={false}>Dismiss me</Alert.alert>
          """
        end)

      assert html =~ "lui-alert-close"
      assert html =~ ~s(aria-label="Close")
      assert html =~ "phx-click"
    end

    test "on_close shows the close button and drives its phx-click (Fluxon parity)" do
      html =
        render(fn assigns ->
          ~H"""
          <Alert.alert id="a3" title="Flash" on_close={Phoenix.LiveView.JS.push("clear")}>
            Dismissible
          </Alert.alert>
          """
        end)

      # on_close implies dismissible even with the default hide_close=true
      assert html =~ "lui-alert-close"
      assert html =~ "phx-click"
      assert html =~ "clear"
    end

    test "default icon by color; hide_icon suppresses it" do
      html =
        render(fn assigns ->
          ~H"""
          <Alert.alert color="warning" title="Careful" />
          """
        end)

      assert html =~ "lui-alert-icon"
      assert html =~ "lui-icon"

      html =
        render(fn assigns ->
          ~H"""
          <Alert.alert color="info" title="Info" hide_icon />
          """
        end)

      refute html =~ "lui-alert-icon"
    end
  end

  describe "separator/1" do
    test "horizontal default" do
      html =
        render(fn assigns ->
          ~H"""
          <Separator.separator />
          """
        end)

      assert html =~ "lui-separator"
      assert html =~ ~s(role="separator")
      assert html =~ ~s(aria-orientation="horizontal")
      refute html =~ "data-vertical"
    end

    test "vertical and text variants" do
      html =
        render(fn assigns ->
          ~H"""
          <Separator.separator vertical />
          """
        end)

      assert html =~ "data-vertical"
      assert html =~ ~s(aria-orientation="vertical")

      html =
        render(fn assigns ->
          ~H"""
          <Separator.separator text="or" />
          """
        end)

      assert html =~ "lui-separator-text"
      assert html =~ "or"
    end
  end
end
