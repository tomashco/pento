defmodule MembraneOpenAI.OpenAIWebSocket do
  use WebSockex
  require Logger

  def start_link(opts) do
    WebSockex.start_link(
      "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01",
      __MODULE__,
      %{parent: self()},
      opts
    )
  end

  @impl true
  def handle_frame(frame, state) do
    send(state.parent, {:websocket_frame, frame})
    {:ok, state}
  end

  def send_frame(ws, frame), do: WebSockex.send_frame(ws, {:text, frame})
end
