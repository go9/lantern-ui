defmodule LanternUI.DateRangePopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias LanternUI.Components.DateRangePopover

  describe "rendering" do
    test "renders default trigger button and popover structure" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "test-dates",
          preset: "30D"
        )

      assert html =~ "id=\"test-dates\""
      assert html =~ "id=\"test-dates-trigger\""
      assert html =~ "Last 30 days"
      assert html =~ "lui-date-range-popover__panel"
      assert html =~ "role=\"radiogroup\""
      assert html =~ "aria-label=\"Date range presets\""
      assert html =~ "value=\"30D\""
      assert html =~ "checked"
      assert html =~ "is-active"
      assert html =~ "Compare with previous period"
    end

    test "renders standard presets" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "presets-popover",
          preset: "7D"
        )

      for p <- ~w(7D 30D 90D MTD QTD YTD custom) do
        assert html =~ "value=\"#{p}\""
      end

      assert html =~ "Last 7 days"
      assert html =~ "value=\"7D\" checked"
    end

    test "supports custom trigger slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <DateRangePopover.date_range_popover id="custom-trig" preset="90D">
          <:trigger>
            <button id="my-custom-btn" type="button">Select Period</button>
          </:trigger>
        </DateRangePopover.date_range_popover>
        """)

      assert html =~ "id=\"my-custom-btn\""
      assert html =~ "Select Period"
      refute html =~ "id=\"custom-trig-trigger\""
    end

    test "renders custom dates and name_prefix" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "custom-dates",
          preset: "custom",
          start_date: ~D[2026-09-01],
          end_date: ~D[2026-09-30],
          name_prefix: "analytics"
        )

      assert html =~ "2026-09-01 – 2026-09-30"
      assert html =~ "name=\"analytics[preset]\""
      assert html =~ "name=\"analytics[start_date]\" value=\"2026-09-01\""
      assert html =~ "name=\"analytics[end_date]\" value=\"2026-09-30\""
      assert html =~ "name=\"analytics[compare_previous]\""
    end

    test "renders comparison toggle and custom label" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "cmp-dates",
          compare_previous: true,
          compare_label: "Compare to previous year"
        )

      assert html =~ "checked"
      assert html =~ "Compare to previous year"

      html_no_cmp =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "no-cmp-dates",
          show_compare: false
        )

      refute html_no_cmp =~ "lui-date-range-popover__compare"
    end

    test "renders validation error state" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "err-dates",
          preset: "custom",
          error: "Start date cannot be after end date"
        )

      assert html =~ "role=\"alert\""
      assert html =~ "Start date cannot be after end date"
      assert html =~ "aria-invalid=\"true\""
    end

    test "renders explicit apply button when requested" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "apply-dates",
          apply_button: true
        )

      assert html =~ "lui-date-range-popover__apply-btn"
      assert html =~ "Apply"
    end

    test "respects min and max bounds" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "bounded-dates",
          min: ~D[2026-01-01],
          max: ~D[2026-12-31]
        )

      assert html =~ "min=\"2026-01-01\""
      assert html =~ "max=\"2026-12-31\""
    end

    test "honors disabled state" do
      html =
        render_component(&DateRangePopover.date_range_popover/1,
          id: "dis-dates",
          disabled: true
        )

      assert html =~
               "<button type=\"button\" id=\"dis-dates-trigger\" class=\"lui-date-range-popover__trigger\" disabled"
    end
  end

  describe "helper functions" do
    test "preset_range/2 returns accurate date windows" do
      anchor = ~D[2026-10-09]

      assert DateRangePopover.preset_range("7D", anchor) == %{
               start_date: ~D[2026-10-03],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("30D", anchor) == %{
               start_date: ~D[2026-09-10],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("90D", anchor) == %{
               start_date: ~D[2026-07-12],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("MTD", anchor) == %{
               start_date: ~D[2026-10-01],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("QTD", anchor) == %{
               start_date: ~D[2026-10-01],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("YTD", anchor) == %{
               start_date: ~D[2026-01-01],
               end_date: ~D[2026-10-09]
             }

      assert DateRangePopover.preset_range("custom", anchor) == nil
    end

    test "comparison_range/2 computes preceding window of identical duration" do
      # 7-day range (Oct 3 to Oct 9) -> previous period is Sep 26 to Oct 2 (7 days)
      cmp = DateRangePopover.comparison_range(~D[2026-10-03], ~D[2026-10-09])
      assert cmp == %{start_date: ~D[2026-09-26], end_date: ~D[2026-10-02]}
      assert Date.diff(cmp.end_date, cmp.start_date) == 6

      # Works with ISO strings
      cmp_str = DateRangePopover.comparison_range("2026-10-03", "2026-10-09")
      assert cmp_str == %{start_date: ~D[2026-09-26], end_date: ~D[2026-10-02]}
    end

    test "validate_range/3 verifies date sequence and bounds" do
      assert {:ok, _} = DateRangePopover.validate_range(~D[2026-10-01], ~D[2026-10-09])
      assert {:ok, _} = DateRangePopover.validate_range("2026-10-01", "2026-10-09")

      assert {:error, "Start date cannot be after end date"} =
               DateRangePopover.validate_range(~D[2026-10-10], ~D[2026-10-09])

      assert {:error, "Start date cannot be before 2026-10-01"} =
               DateRangePopover.validate_range(~D[2026-09-20], ~D[2026-10-09],
                 min: ~D[2026-10-01]
               )

      assert {:error, "End date cannot be after 2026-10-15"} =
               DateRangePopover.validate_range(~D[2026-10-01], ~D[2026-10-20],
                 max: ~D[2026-10-15]
               )

      assert {:error, "Invalid date format"} =
               DateRangePopover.validate_range("not-a-date", "2026-10-09")
    end

    test "format_range_label/3 produces human-readable labels" do
      assert DateRangePopover.format_range_label("7D") == "Last 7 days"
      assert DateRangePopover.format_range_label("30D") == "Last 30 days"
      assert DateRangePopover.format_range_label("MTD") == "Month to date"
      assert DateRangePopover.format_range_label("QTD") == "Quarter to date"
      assert DateRangePopover.format_range_label("YTD") == "Year to date"

      assert DateRangePopover.format_range_label("custom", ~D[2026-09-01], ~D[2026-09-30]) ==
               "2026-09-01 – 2026-09-30"

      assert DateRangePopover.format_range_label("custom") == "Custom range"
    end
  end
end
