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

    # Count only this component's line: async tests share the log capture, so
    # another component's deprecation (e.g. <.segmented>) can land in it too.
    assert log =~ "#{name}/1 is deprecated"
    assert log =~ "<.button>"
    assert length(Regex.scan(~r/#{name}\/1 is deprecated/, log)) == 1
    assert length(Regex.scan(~r/#{name}\/1 is deprecated and will be removed in 0.9.0/, log)) == 1
  end

  test "warn/3 names the removal version the entry declares" do
    name = :"removal_#{System.unique_integer([:positive])}"

    log =
      capture_log(fn ->
        assert :ok = LanternUI.Deprecated.warn(name, "<.page_shell>", "1.0")
      end)

    assert log =~ "#{name}/1 is deprecated and will be removed in 1.0; use <.page_shell>"
  end

  test "every deprecated entry names its removal version and replacement" do
    for entry <- LanternUI.Deprecated.deprecated() do
      assert is_binary(entry.removed_in)
      assert is_binary(entry.replacement)
    end
  end
end
