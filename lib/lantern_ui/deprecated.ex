defmodule LanternUI.Deprecated do
  @moduledoc false
  require Logger

  @doc """
  Emit a deprecation warning once per BEAM node per component name.
  """
  def warn(component, replacement) when is_atom(component) and is_binary(replacement) do
    key = {__MODULE__, component}

    unless :persistent_term.get(key, false) do
      :persistent_term.put(key, true)

      Logger.warning(
        "LanternUI #{component}/1 is deprecated and will be removed in 0.9.0; use #{replacement} instead"
      )
    end

    :ok
  end
end
