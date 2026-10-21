defmodule LanternUI.QA.StageStripLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       states: [:done, :active, :waiting, :pending, :skipped, :failed],
       stages: [
         %{label: "Triaged", state: :done},
         %{label: "Drafted", state: :skipped},
         %{label: "Decided", state: :waiting},
         %{label: "In work", state: :pending},
         %{label: "Shipped", state: :pending},
         %{label: "Told", state: :pending}
       ]
     )}
  end

  def render(assigns) do
    ~H"""
    <.page_shell id="stage-strip-demo" title="Stage strip">
      <p>A compact workflow summary. Follow the report link for its full trace.</p>
      <.list_row id="suggestion-19" title="Image upload fails on iPhone" href="#trace">
        <:meta>Link #212 · 2 reports</:meta>
        <:trailing><.stage_strip stages={@stages} /></:trailing>
      </.list_row>
      <h2 id="trace">State reference</h2>
      <p :for={state <- @states}>
        <.stage_strip stages={[%{label: "Example", state: state}]} /> {state}
      </p>
    </.page_shell>
    """
  end
end
