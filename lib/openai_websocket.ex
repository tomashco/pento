defmodule MembraneOpenAI.OpenAIWebSocket do
  use WebSockex
  require Logger

  def start_link(opts) do
    WebSockex.start_link(
      "wss://api.openai.com/v1/realtime?model=gpt-realtime",
      __MODULE__,
      %{parent: self()},
      opts
    )
  end

  @impl true
  def handle_connect(conn, state) do
    # Build the session.update event with custom options
    # init_event = %{
    #   "type" => "session.update",
    #   "session" => %{
    #     "instructions" =>
    #       "Your name is JOSE and when the conversation starts you tell who you are.",
    #     "type" => "realtime",
    #     "tools" => [
    #       %{
    #         "type" => "function",
    #         "name" => "get_horoscope",
    #         "description" => "Get today's horoscope for an astrological sign.",
    #         "parameters" => %{
    #           "type" => "object",
    #           "properties" => %{
    #             "sign" => %{
    #               "type" => "string",
    #               "description" => "An astrological sign like Taurus or Aquarius"
    #             }
    #           },
    #           "required" => ["sign"]
    #         }
    #       }
    #     ]
    #   }
    # }

    # :ok =
    #   MembraneOpenAI.OpenAIWebSocket.send_frame(ws, vad_event)
    # WebSockex.send_frame(self(), {:text, frame})
    # |> IO.inspect(label: "dadas")
    WebSockex.cast(self(), :send_frame)

    {:ok, state}
  end

  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_cast(:send_frame, state) do
    session_update =
      %{
        "type" => "session.update",
        "session" => %{
          "turn_detection" => %{
            "type" => "server_vad",
            "threshold" => 0.5,
            "prefix_padding_ms" => 300,
            "silence_duration_ms" => 500,
            "create_response" => true,
            "interrupt_response" => false
          }
        }
      }

    state
    |> IO.inspect(label: "handle_cast")

    frame =
      Jason.encode!(session_update)

    {:reply, {:text, frame}, state}
  end

  @impl true
  def handle_frame(frame, state) do
    send(state.parent, {:websocket_frame, frame})
    {:ok, state}
  end

  def send_frame(ws, frame) do
    WebSockex.send_frame(ws, {:text, frame})
  end
end
