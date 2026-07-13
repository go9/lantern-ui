defmodule LanternUI.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Calendar

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "icon/1" do
    test "renders an inline svg with the named path" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Icon.icon name="chevron-down" />
          """
        end)

      assert html =~ ~s(class="lui-icon")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "<path"
    end
  end

  describe "button/1" do
    test "defaults mirror Fluxon: outline/primary/md" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Button.button>Save</LanternUI.Components.Button.button>
          """
        end)

      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-color="primary")
      assert html =~ ~s(data-size="md")
      assert html =~ ~s(data-part="button")
      assert html =~ "Save"
    end

    test "variant, color, size, disabled, and class-merge" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Button.button
            variant="solid"
            color="danger"
            size="sm"
            disabled
            class="w-full"
          >
            Delete
          </LanternUI.Components.Button.button>
          """
        end)

      assert html =~ ~s(data-variant="solid")
      assert html =~ ~s(data-color="danger")
      assert html =~ ~s(data-size="sm")
      assert html =~ "disabled"
      assert html =~ "lui-btn w-full"
    end

    test "button_group wraps with role=group" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Button.button_group>
            <LanternUI.Components.Button.button>A</LanternUI.Components.Button.button>
          </LanternUI.Components.Button.button_group>
          """
        end)

      assert html =~ ~s(role="group")
      assert html =~ "lui-btn-group"
    end
  end

  describe "input/1" do
    test "renders label, help text, and the input" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Form.input
            id="email"
            name="email"
            value="a@b.c"
            label="Email"
            help_text="Billing."
          />
          """
        end)

      assert html =~ "lui-label"
      assert html =~ "Email"
      assert html =~ ~s(value="a@b.c")
      assert html =~ "Billing."
      refute html =~ "lui-error"
    end

    test "errors flip aria-invalid and suppress help text" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Form.input
            id="x"
            name="x"
            value=""
            errors={["is required"]}
            help_text="hint"
          />
          """
        end)

      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="x-error")
      assert html =~ "is required"
      refute html =~ "hint"
    end

    test "FormField clause extracts id/name/value" do
      form = Phoenix.Component.to_form(%{"title" => "hello"}, as: :post)

      html =
        render(
          fn assigns ->
            ~H"""
            <LanternUI.Components.Form.input field={@form[:title]} label="Title" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="post[title]")
      assert html =~ ~s(id="post_title")
      assert html =~ ~s(value="hello")
    end

    test "prefix/suffix slots render inside the wrap" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Form.input id="q" name="q" value="">
            <:inner_prefix>PRE</:inner_prefix>
            <:inner_suffix>SUF</:inner_suffix>
          </LanternUI.Components.Form.input>
          """
        end)

      assert html =~ "PRE"
      assert html =~ "SUF"
      assert html =~ "lui-inner-affix"
    end

    test "hidden type renders a bare input" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Form.input type="hidden" id="h" name="h" value="v" />
          """
        end)

      assert html =~ ~s(type="hidden")
      refute html =~ "lui-field"
    end
  end

  describe "calendar/1" do
    test "renders a 6x7 ARIA grid for the month" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Calendar.calendar id="cal" selected={~D[2026-02-03]} />
          """
        end)

      assert html =~ ~s(phx-hook="LanternCalendar")
      assert html =~ ~s(data-month="2026-02-01")
      assert html =~ ~s(data-value="2026-02-03")
      assert html =~ "February 2026"
      # 42 day cells
      assert length(String.split(html, "lui-cal-day")) - 1 == 42
      assert html =~ ~s(aria-selected="true")
    end

    test "min/max disable out-of-range days" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.Calendar.calendar id="cal" month={~D[2026-02-01]} min="2026-02-10" />
          """
        end)

      # Feb 9 disabled, Feb 10 enabled
      assert html =~ ~r/data-date="2026-02-09"[^>]*disabled/
      refute html =~ ~r/data-date="2026-02-10"[^>]*disabled/
    end

    test "weeks/2 grid math respects week_start" do
      # Feb 2026 starts Sunday. week_start=0 -> first cell is Feb 1.
      [[first | _] | _] = Calendar.weeks(~D[2026-02-01], 0)
      assert first == ~D[2026-02-01]

      # week_start=1 (Monday) -> first cell is Mon Jan 26.
      [[first | _] | _] = Calendar.weeks(~D[2026-02-01], 1)
      assert first == ~D[2026-01-26]
    end
  end

  describe "datetime_field/1" do
    test "date mode renders m/d/y segments and the hidden canonical input" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field
            id="f"
            name="due"
            mode={:date}
            value="2026-02-03"
          />
          """
        end)

      assert html =~ ~s(phx-hook="LanternDatetimeField")
      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="due")
      assert html =~ ~s(value="2026-02-03")
      assert html =~ ~s(data-seg="month")
      assert html =~ ~s(data-seg="day")
      assert html =~ ~s(data-seg="year")
      refute html =~ ~s(data-seg="hour")
      # segments show the parsed value, zero-padded
      assert html =~ ">02<"
      assert html =~ ">03<"
      assert html =~ ">2026<"
    end

    test "nil value renders placeholders and an empty hidden input" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field id="f" name="due" mode={:date} value={nil} />
          """
        end)

      assert html =~ ~s(value="")
      assert html =~ "mm"
      assert html =~ "dd"
      assert html =~ "yyyy"
      refute html =~ ~s(data-set="true")
      # nullable default shows the clear affordance
      assert html =~ "lui-dtf-clear"
    end

    test "datetime mode at ms precision renders all segments 12h" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field
            id="f"
            name="at"
            mode={:datetime}
            precision={:millisecond}
            value="2026-02-03T14:30:05.123"
          />
          """
        end)

      for seg <- ~w(month day year hour minute second millisecond meridiem) do
        assert html =~ ~s(data-seg="#{seg}"), "missing segment #{seg}"
      end

      # 14:30 displays as 02:30 PM; ms padded to 123
      assert html =~ ">02<"
      assert html =~ ">30<"
      assert html =~ ">123<"
      assert html =~ ">PM<"
    end

    test "time mode default precision hides seconds/ms" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field
            id="f"
            name="t"
            mode={:time}
            value="08:45:00.000"
          />
          """
        end)

      assert html =~ ~s(data-seg="hour")
      refute html =~ ~s(data-seg="second")
      refute html =~ ~s(data-seg="millisecond")
      assert html =~ ">08<"
      assert html =~ ">45<"
      assert html =~ ">AM<"
    end

    test "midnight and noon map to 12 AM / 12 PM" do
      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field
            id="f"
            name="t"
            mode={:time}
            value="00:15:00.000"
          />
          """
        end)

      assert html =~ ">12<"
      assert html =~ ">AM<"

      html =
        render(fn assigns ->
          ~H"""
          <LanternUI.Components.DatetimeField.datetime_field
            id="g"
            name="t"
            mode={:time}
            value="12:15:00.000"
          />
          """
        end)

      assert html =~ ">12<"
      assert html =~ ">PM<"
    end
  end

  describe "use LanternUI registry" do
    test "exposes the new component groups" do
      keys = LanternUI.__components__() |> Map.keys() |> Enum.sort()

      assert keys == [
               :badge,
               :breadcrumb,
               :button,
               :calendar,
               :charts,
               :checkbox,
               :data_table,
               :date_picker,
               :datetime_field,
               :dropdown,
               :empty_state,
               :form,
               :icon,
               :layout,
               :modal,
               :pagination,
               :select,
               :table,
               :tabs
             ]
    end
  end
end
