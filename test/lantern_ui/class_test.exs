defmodule LanternUI.ClassTest do
  use ExUnit.Case, async: true

  alias LanternUI.Class

  describe "merge/1" do
    test "resolves conflicting Tailwind utilities, last wins" do
      assert Class.merge(["px-2 py-1", "px-4"]) == "py-1 px-4"
    end

    test "a consumer override beats the base class" do
      base = "rounded-md bg-zinc-100 text-sm"
      assert Class.merge([base, "bg-blue-600"]) =~ "bg-blue-600"
      refute Class.merge([base, "bg-blue-600"]) =~ "bg-zinc-100"
    end

    test "drops falsy fragments and flattens nested lists" do
      assert Class.merge(["px-4", nil, false, ["py-2", ""]]) == "px-4 py-2"
    end

    test "accepts a plain string" do
      assert Class.merge("px-2 px-4") == "px-4"
    end
  end

  describe "variant/3" do
    test "selects the fragment for the key" do
      variants = %{primary: "bg-accent", ghost: "bg-transparent"}
      assert Class.variant(variants, :primary) == "bg-accent"
    end

    test "falls back to the default for an unknown key" do
      assert Class.variant(%{primary: "x"}, :nope, "fallback") == "fallback"
    end
  end
end
