defmodule LanternUI.QA.ConversationLive do
  @moduledoc false
  # Demo for the conversation recipe: append while reading, rejected draft
  # kept, action-card ids. Same HEEx as test/support/recipes/conversation.html.heex.
  #
  #   /conversation
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket) do
    {:ok, assign(socket, LanternUI.Recipes.fixture_assigns())}
  end

  def handle_event("draft", %{"draft" => text}, socket) do
    {:noreply, assign(socket, draft: text)}
  end

  def handle_event("send", params, socket) do
    text = params |> Map.get("draft", socket.assigns.draft) |> to_string() |> String.trim()

    cond do
      text == "" ->
        {:noreply, assign(socket, send_error: "Message can't be blank.")}

      text == "fail" ->
        {:noreply,
         assign(socket,
           draft: text,
           send_error: "The run rejected this message. Edit the draft and send again."
         )}

      true ->
        n = length(socket.assigns.messages) + 1

        msg = %{
          id: "m#{n}",
          role: :user,
          author: "You",
          initials: "JO",
          content: text,
          at: "now"
        }

        {:noreply,
         socket
         |> update(:messages, &(&1 ++ [msg]))
         |> assign(draft: "", send_error: nil)}
    end
  end

  def handle_event("approve", %{"id" => id}, socket) do
    if socket.assigns.action && socket.assigns.action.id == id do
      {:noreply, assign(socket, action: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("reject", %{"id" => id}, socket) do
    if socket.assigns.action && socket.assigns.action.id == id do
      {:noreply, assign(socket, action: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("seen", %{"message_id" => _id}, socket), do: {:noreply, socket}

  def handle_event("append", _params, socket) do
    n = length(socket.assigns.messages) + 1

    msg = %{
      id: "m#{n}",
      role: :assistant,
      author: "Assistant",
      initials: "AI",
      content: "Appended while you read history (#{n}).",
      at: "now"
    }

    {:noreply, update(socket, :messages, &(&1 ++ [msg]))}
  end

  def render(assigns) do
    ~H"""
    <div id="qa-conversation" style="padding: var(--lantern-space-lg);">
      <.button id="qa-append" phx-click="append">Append while reading</.button>
      {LanternUI.Recipes.conversation(assigns)}
    </div>
    """
  end
end
