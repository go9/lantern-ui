defmodule LanternUI.Charts.GeometryTest do
  use ExUnit.Case, async: true

  alias LanternUI.Charts.Geometry

  describe "scale/5" do
    test "maps a value from domain to range" do
      assert Geometry.scale(0, 10, 0, 100, 5) == 50.0
    end

    test "supports an inverted range (SVG y axis)" do
      assert Geometry.scale(0, 10, 100, 0, 0) == 100.0
      assert Geometry.scale(0, 10, 100, 0, 10) == 0.0
    end

    test "degenerate domain maps to range midpoint" do
      assert Geometry.scale(5, 5, 0, 100, 5) == 50.0
    end
  end

  describe "nice_ticks/3" do
    test "returns ascending ticks covering the range" do
      ticks = Geometry.nice_ticks(2, 38, 5)
      assert ticks == Enum.sort(ticks)
      assert hd(ticks) <= 2
      assert List.last(ticks) >= 38
    end

    test "handles a flat range without crashing" do
      ticks = Geometry.nice_ticks(10, 10, 5)
      assert length(ticks) > 1
    end
  end

  describe "line_path/2 and area_path/3" do
    test "straight path uses line segments, no curves" do
      d = Geometry.line_path([{0, 0}, {10, 5}, {20, 0}], false)
      assert String.starts_with?(d, "M0.0,0.0")
      assert String.contains?(d, "L10.0,5.0")
      refute String.contains?(d, "C")
    end

    test "smooth path uses cubic bezier segments" do
      d = Geometry.line_path([{0, 0}, {10, 5}, {20, 0}], true)
      assert String.contains?(d, "C")
    end

    test "single point yields a move only" do
      assert Geometry.line_path([{3, 4}], true) == "M3.0,4.0"
    end

    test "empty points yield empty path" do
      assert Geometry.line_path([], true) == ""
    end

    test "area path closes back to the baseline" do
      d = Geometry.area_path([{0, 0}, {10, 5}], 100, false)
      assert String.ends_with?(d, "Z")
      assert String.contains?(d, "100.0")
    end
  end
end
