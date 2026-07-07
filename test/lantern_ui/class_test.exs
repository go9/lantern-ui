defmodule LanternUI.ClassTest do
  use ExUnit.Case, async: true

  alias LanternUI.Class

  describe "merge/1" do
    test "joins fragments in order (consumer classes append after base)" do
      assert Class.merge(["lui-btn", "w-full"]) == "lui-btn w-full"
    end

    test "drops falsy fragments and flattens nested lists" do
      assert Class.merge(["lui-btn", nil, false, ["w-full", ""]]) == "lui-btn w-full"
    end

    test "accepts a plain string and nil" do
      assert Class.merge("lui-btn") == "lui-btn"
      assert Class.merge(nil) == ""
    end
  end

  describe "variant/3" do
    test "selects the fragment for the key" do
      variants = %{primary: "lui-a", ghost: "lui-b"}
      assert Class.variant(variants, :primary) == "lui-a"
    end

    test "falls back to the default for an unknown key" do
      assert Class.variant(%{primary: "x"}, :nope, "fallback") == "fallback"
    end
  end
end
