defmodule LanternUI.ImportSurfaceTest do
  use ExUnit.Case, async: true

  alias LanternUI

  # This is the complete set of non-component imports intentionally retained
  # for compatibility. Helpers remain available through their module names.
  @known_import_helpers []

  test "use LanternUI exposes only documented function components and known helpers" do
    imported =
      LanternUI.__filter_components__([], [])
      |> Enum.flat_map(fn {_key, module} ->
        Enum.map(LanternUI.__component_imports__(module), &{module, &1})
      end)
      |> MapSet.new()

    documented_components =
      LanternUI.__filter_components__([], [])
      |> Enum.flat_map(fn {_key, module} ->
        module.__components__()
        |> Enum.filter(fn {_name, metadata} -> metadata.kind == :def end)
        |> Enum.map(fn {name, _metadata} -> {module, {name, 1}} end)
      end)
      |> MapSet.new()

    allowed = MapSet.union(documented_components, MapSet.new(@known_import_helpers))

    assert imported == documented_components
    assert MapSet.subset?(imported, allowed)
  end

  test "consumer-local helpers with common names compile alongside use LanternUI" do
    module = Module.concat(__MODULE__, "ConsumerWithCommonHelpers")

    source = """
    defmodule #{inspect(module)} do
      use LanternUI
      import Kernel, except: [to_string: 1]

      defp parse_date(value), do: {:parse_date, value}
      defp format_date(value), do: {:format_date, value}
      defp format_number(value), do: {:format_number, value}
      defp humanize(value), do: {:humanize, value}
      defp to_string(value), do: {:to_string, value}

      def local_helpers do
        {
          parse_date(:value),
          format_date(:value),
          format_number(:value),
          humanize(:value),
          to_string(:value)
        }
      end
    end
    """

    Code.compile_string(source)

    assert apply(module, :local_helpers, []) ==
             {{:parse_date, :value}, {:format_date, :value}, {:format_number, :value},
              {:humanize, :value}, {:to_string, :value}}
  end
end
