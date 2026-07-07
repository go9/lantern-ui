defmodule LanternUI.Class do
  @moduledoc """
  Class-string composition for LanternUI components.

  `merge/1` flattens nested class lists, drops falsy fragments, and joins —
  so conditional class lists from HEEx compose cleanly with a component's
  base classes:

      LanternUI.Class.merge(["lui-btn", @wide && "lui-btn-wide", @class])

  No Tailwind-conflict engine is needed by design: LanternUI's own classes are
  namespaced semantic classes (`lui-*`), never Tailwind utilities, so a
  consumer's `class=` override cannot conflict with a component base. (We
  evaluated twix/tails/tailwind_merge; twix crashes on non-Tailwind class
  names via `binary_to_existing_atom`, and none is needed for this model —
  dropping the dependency also keeps the package fully self-contained.)

  `variant/3` selects a class fragment from a variants map.
  """

  @doc """
  Compose class fragments into one class string.

  Accepts a string or a (possibly nested) list; `nil`, `false`, and `""`
  entries are dropped.
  """
  def merge(classes) when is_list(classes) do
    classes
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.join(" ")
  end

  def merge(classes) when is_binary(classes), do: classes
  def merge(nil), do: ""

  @doc """
  Return the class fragment for `key` from a `variants` map, or `default`.

      LanternUI.Class.variant(%{primary: "…", ghost: "…"}, @variant, "")
  """
  def variant(variants, key, default \\ nil) when is_map(variants) do
    Map.get(variants, key, default)
  end
end
