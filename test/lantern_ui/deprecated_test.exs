defmodule LanternUI.DeprecatedTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  test "warns once per component name per node" do
    name = :"fold_#{System.unique_integer([:positive])}"

    log =
      capture_log(fn ->
        assert :ok = LanternUI.Deprecated.warn(name, "<.button>")
        assert :ok = LanternUI.Deprecated.warn(name, "<.button>")
      end)

    assert log =~ "#{name}/1 is deprecated"
    assert log =~ "<.button>"
    assert length(Regex.scan(~r/will be removed in 0.9.0/, log)) == 1
  end
end
