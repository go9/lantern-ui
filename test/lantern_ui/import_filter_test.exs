defmodule LanternUI.ImportFilterTest do
  use ExUnit.Case, async: true

  # A module compiles calling `fun(assigns)` only if `fun` is imported.
  defp compiles?(use_line, call) do
    mod = "IF#{System.unique_integer([:positive])}"

    try do
      Code.compile_string("""
      defmodule #{mod} do
        #{use_line}
        def f(assigns), do: #{call}
      end
      """)

      true
    rescue
      _ -> false
    end
  end

  test "except: [icon: 1] drops icon/1 but keeps other components" do
    refute compiles?("use LanternUI, except: [icon: 1]", "icon(assigns)")
    assert compiles?("use LanternUI, except: [icon: 1]", "button(assigns)")
  end

  test "except: [icon: 1, translate_error: 1] drops both (the flicker case)" do
    refute compiles?(
             "use LanternUI, except: [icon: 1, translate_error: 1]",
             "translate_error(assigns)"
           )

    assert compiles?("use LanternUI, except: [icon: 1, translate_error: 1]", "input(assigns)")
  end

  test "except: [:charts] still filters by component key" do
    refute compiles?("use LanternUI, except: [:charts]", "area_chart(assigns)")
    assert compiles?("use LanternUI, except: [:charts]", "button(assigns)")
  end

  test "only: [button: 1] imports just that function" do
    assert compiles?("use LanternUI, only: [button: 1]", "button(assigns)")
    refute compiles?("use LanternUI, only: [button: 1]", "badge(assigns)")
  end

  test "stat registry key imports the standalone stat components" do
    assert compiles?("use LanternUI, only: [:stat]", "stat_card(assigns)")
    assert compiles?("use LanternUI, only: [:stat]", "stat_grid(assigns)")
    refute compiles?("use LanternUI, except: [:stat]", "stat_card(assigns)")
  end
end
