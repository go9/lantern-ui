defmodule LanternUI.DatePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.DatePicker

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "date_picker/1" do
    test "composes field + toggle + calendar panel behind the Fluxon surface" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_picker id="due" name="due" value="2026-02-03" label="Due date" />
          """
        end)

      assert html =~ ~s(phx-hook="LanternPicker")
      assert html =~ ~s(phx-hook="LanternDatetimeField")
      assert html =~ ~s(phx-hook="LanternCalendar")
      assert html =~ "Due date"
      # hidden canonical input
      assert html =~ ~s(name="due")
      assert html =~ ~s(value="2026-02-03")
      # toggle + dialog panel
      assert html =~ ~s(aria-haspopup="dialog")
      assert html =~ ~s(role="dialog")
      assert html =~ "Today"
      assert html =~ "Done"
      # calendar selected on the value's month
      assert html =~ ~s(data-month="2026-02-01")
    end

    test "form attribute is forwarded to the hidden value input" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_picker id="d" name="row[d]" value="2026-02-03" form="edit-row-7" />
          """
        end)

      assert html =~ ~s(type="hidden" name="row[d]" value="2026-02-03" form="edit-row-7")
    end

    test "FormField clause extracts id/name/value and errors" do
      form = Phoenix.Component.to_form(%{"due" => "2026-05-10"}, as: :thing)

      html =
        render(
          fn assigns ->
            ~H"""
            <DatePicker.date_picker field={@form[:due]} />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="thing[due]")
      assert html =~ ~s(value="2026-05-10")
    end

    test "min/max/week_start forward to the calendar" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_picker
            id="d"
            name="d"
            value={nil}
            min="2026-01-01"
            max="2026-12-31"
            week_start={1}
          />
          """
        end)

      assert html =~ ~s(data-min="2026-01-01")
      assert html =~ ~s(data-max="2026-12-31")
      assert html =~ ~s(data-week-start="1")
    end
  end

  describe "date_time_picker/1 panel time pane" do
    test "datetime panel includes the time pane, wired but non-submitting" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_time_picker id="ts" name="ts" value="2026-02-03T14:30:00.500" />
          """
        end)

      assert html =~ ~s(data-part="panel-time")
      assert html =~ "Time"
      assert html =~ ~s(aria-label="Choose date and time")
      # panel time field is seeded from the value's time slice...
      assert html =~ "14:30:00.500"
      # ...but its hidden input has NO name, so it never submits
      refute html =~ ~r/<input type="hidden" name="[^"]+" value="14:30:00\.500"/
    end

    test "date mode has no time pane" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_picker id="d" name="d" value="2026-02-03" />
          """
        end)

      refute html =~ ~s(data-part="panel-time")
      assert html =~ ~s(aria-label="Choose date")
    end
  end

  describe "date_time_picker/1" do
    test "renders datetime segments and Now in the footer" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.date_time_picker
            id="at"
            name="at"
            value="2026-02-03T14:30:00.000"
            precision={:millisecond}
          />
          """
        end)

      assert html =~ ~s(data-mode="datetime")
      assert html =~ ~s(data-seg="millisecond")
      assert html =~ "Now"
      assert html =~ ~s(value="2026-02-03T14:30:00.000")
    end
  end

  describe "time_picker/1" do
    test "segments only — no popover, no toggle" do
      html =
        render(fn assigns ->
          ~H"""
          <DatePicker.time_picker id="t" name="t" value="08:45:00.000" />
          """
        end)

      assert html =~ ~s(data-mode="time")
      assert html =~ ~s(data-seg="hour")
      refute html =~ ~s(role="dialog")
      refute html =~ "lui-picker-toggle"
      assert html =~ ~s(value="08:45:00.000")
    end
  end

  describe "canonical/2 value normalization" do
    test "structs normalize to the canonical strings" do
      assert DatePicker.canonical(~D[2026-02-03], :date) == "2026-02-03"
      assert DatePicker.canonical(~T[08:45:00], :time) == "08:45:00.000"
      assert DatePicker.canonical(~T[08:45:00.123456], :time) == "08:45:00.123"

      assert DatePicker.canonical(~N[2026-02-03 14:30:05.123], :datetime) ==
               "2026-02-03T14:30:05.123"

      assert DatePicker.canonical(~U[2026-02-03 14:30:05.123Z], :datetime) ==
               "2026-02-03T14:30:05.123"

      assert DatePicker.canonical(nil, :date) == nil
      assert DatePicker.canonical("", :date) == nil
      assert DatePicker.canonical("2026-02-03", :date) == "2026-02-03"
    end
  end
end
