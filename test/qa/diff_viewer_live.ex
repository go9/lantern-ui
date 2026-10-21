defmodule LanternUI.QA.DiffViewerLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  @old Enum.map_join(1..12, "\n", &"line #{&1}") |> String.replace("line 6", "name: contract")
  @new Enum.map_join(1..12, "\n", &"line #{&1}")
       |> String.replace("line 6", "name: contract v2\nowner: infra")

  def mount(_params, _session, socket), do: {:ok, assign(socket, old: @old, new: @new)}

  def render(assigns) do
    ~H"""
    <.page_shell id="diff-viewer-demo" title="Diff viewer">
      <h2>Unified</h2>
      <.diff_viewer id="unified" old={@old} new={@new} old_label="Server" new_label="Draft" />
      <h2>Side by side</h2>
      <.diff_viewer
        id="split"
        old={@old}
        new={@new}
        mode={:split}
        old_label="Server"
        new_label="Draft"
      />
      <h2>No changes</h2>
      <.diff_viewer id="same" old={@old} new={@old} />
    </.page_shell>
    """
  end
end
