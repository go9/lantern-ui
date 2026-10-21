defmodule LanternUI.QA.TraceLive do
  @moduledoc false
  # Demo for the run-trace recipe: follow-aware timeline, disclosure that
  # survives append, live/paused/done. Same HEEx as
  # test/support/recipes/trace.html.heex.
  #
  #   /trace
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    socket = assign(socket, LanternUI.Recipes.fixture_assigns())
    open_id = params["event"]

    events =
      Enum.map(socket.assigns.events, fn event ->
        %{event | open: open_id != nil && event.id == open_id}
      end)

    {:ok, socket |> assign(events: events, seq: length(events)) |> schedule_tick()}
  end

  def handle_event("pause_run", _params, socket) do
    {:noreply, assign(socket, run: %{socket.assigns.run | state: :paused})}
  end

  def handle_event("resume_run", _params, socket) do
    {:noreply,
     socket
     |> assign(run: %{socket.assigns.run | state: :live})
     |> schedule_tick()}
  end

  def handle_event("finish_run", _params, socket) do
    {:noreply, assign(socket, run: %{socket.assigns.run | state: :done})}
  end

  def handle_info(:tick, socket) do
    if socket.assigns.run.state == :live do
      n = socket.assigns.seq + 1

      event = %{
        id: "e#{n}",
        title: "event #{n}",
        label: "Running",
        at: time_label(n),
        status: :active,
        open: false,
        anchor: true,
        detail: "tick #{n} — still ingesting while follow may be paused",
        channel: "run",
        severity: :info
      }

      events = Enum.map(socket.assigns.events, &%{&1 | anchor: false}) ++ [event]

      {:noreply, socket |> assign(events: events, seq: n) |> schedule_tick()}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div id="qa-trace" style="padding: var(--lantern-space-lg);">
      <.button id="qa-finish" phx-click="finish_run">Mark done</.button>
      {LanternUI.Recipes.trace(assigns)}
    </div>
    """
  end

  defp schedule_tick(socket) do
    if socket.assigns.run.state == :live do
      Process.send_after(self(), :tick, 1500)
    end

    socket
  end

  defp time_label(n) do
    seconds = 10 + rem(n, 50)
    "12:04:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end
end
