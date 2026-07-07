defmodule LanternUI.Class do
  @moduledoc """
  Class-string composition for LanternUI components.

  `merge/1` resolves Tailwind conflicts (last value wins) via
  [twix](https://hex.pm/packages/twix), so a consumer's `class=` override cleanly
  beats a component's base classes. `variant/3` selects a class fragment from a
  variants map. Together they cover Fluxon-style customization — base + variant +
  user override — without pulling in a heavier component toolkit.

      LanternUI.Class.merge(["px-3 py-2 rounded-md", @variant, @class])

  Falsy fragments (`nil`, `false`, `""`) are dropped, so conditional class lists
  from HEEx work directly.
  """

  @doc """
  Merge class fragments, resolving Tailwind utility conflicts (last wins).

  Accepts a string or a (possibly nested) list of strings; falsy entries are
  ignored.
  """
  def merge(classes) when is_list(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Twix.tw()
  end

  def merge(classes) when is_binary(classes), do: Twix.tw(classes)
  def merge(nil), do: ""

  @doc """
  Return the class fragment for `key` from a `variants` map, or `default`.

      LanternUI.Class.variant(%{primary: "bg-... text-...", ghost: "..."}, @variant, "")
  """
  def variant(variants, key, default \\ nil) when is_map(variants) do
    Map.get(variants, key, default)
  end
end
