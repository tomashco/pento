defmodule MembraneOpenAI.OpenAIEndpoint do
  @moduledoc """
  An element that handles communication with the OpenAI Whisper/TTS API via a WebSocket,
  buffers the incoming response audio, and pushes it downstream at a configurable pace.
  """
  use Membrane.Filter
  require Membrane.Logger

  alias Membrane.Buffer
  # Used for type reference in original code
  alias Membrane.BufferDiscarder.Events.Flush
  alias Membrane.Realtimer.Events.Reset

  def_input_pad(:input, accepted_format: _any)
  def_output_pad(:output, accepted_format: _any, flow_control: :push)

  def_options(websocket_opts: [])

  # time in nanoseconds -> 100 millis
  @interval 200_000_000

  @impl true
  def handle_init(_ctx, opts) do
    {:ok, ws} = MembraneOpenAI.OpenAIWebSocket.start_link(opts.websocket_opts)

    state = %{
      ws: ws,
      queue: :queue.new(),
      timer_status: nil
    }

    {[], state}
  end

  @impl true
  def handle_playing(_ctx, state) do
    # Standard format for OpenAI voice streaming, the audio sent to openai
    Membrane.Logger.info("Starting audio streaming and setting format.")
    format = %Membrane.RawAudio{channels: 1, sample_rate: 24_000, sample_format: :s16le}
    {[stream_format: {:output, format}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    # This pad receives user audio input, which is immediately forwarded to the WebSocket.
    audio = Base.encode64(buffer.payload)
    frame = %{type: "input_audio_buffer.append", audio: audio} |> Jason.encode!()

    :ok =
      MembraneOpenAI.OpenAIWebSocket.send_frame(state.ws, frame)

    {[], state}
  end

  # Timer that sends buffer to output pad
  @impl true
  def handle_tick(:pacer, _ctx, state) do
    Membrane.Logger.info(
      "Calling handle_tick, #{:queue.len(state.queue)}, timer status: #{state.timer_status}"
    )

    case :queue.out(state.queue) do
      {:empty, _queue} ->
        # Queue is empty, stop the timer until new audio arrives
        Membrane.Logger.info("Pacing done, queue empty. Stopping timer.")
        {[stop_timer: :pacer], %{state | timer_status: nil}}

      {{:value, buffer_to_send}, rest_of_queue} ->
        # Found a buffer, send it downstream
        actions = [buffer: {:output, buffer_to_send}]

        Membrane.Logger.info("Sending buffer")
        # More buffers remain, restart the timer for the next interval
        {
          actions ++
            [],
          %{
            state
            | queue: rest_of_queue
          }
        }
    end
  end

  @impl true
  def get_time() do
    :os.system_time(:millisecond)
  end

  @impl true
  def handle_info({:websocket_frame, {:text, frame}}, _ctx, state) do
    case Jason.decode!(frame) do
      %{"type" => "session.updated"} ->
        {[], state}

      %{"type" => "function_call", "name" => name} ->
        Membrane.Logger.info("FUNCTION CALL: #{name}")
        {[], state}

      %{"type" => "input_audio_buffer.speech_started"} ->
        Membrane.Logger.info("User is Speaking, stopping AI response and flushing queue")

        # Cancel the current response from OpenAI
        frame = %{type: "response.cancel"} |> Jason.encode!()
        :ok = MembraneOpenAI.OpenAIWebSocket.send_frame(state.ws, frame)

        timer_is_running = !is_nil(state.timer_status)

        actions =
          if timer_is_running do
            Membrane.Logger.info("stopping timer")
            [stop_timer: :pacer]
          else
            []
          end

        {actions, %{state | queue: :queue.new(), timer_status: nil}}

      %{"type" => "response.audio.delta", "delta" => delta} ->
        Membrane.Logger.debug("Receiving response delta and enqueueing buffer")
        audio_payload = Base.decode64!(delta)
        buffer = %Membrane.Buffer{payload: audio_payload}
        new_queue = :queue.in(buffer, state.queue)

        should_start_timer = is_nil(state.timer_status)
        now = :os.system_time(:millisecond)
        # Determine the new state
        new_state =
          if should_start_timer do
            %{
              state
              | timer_status: :running,
                queue: new_queue
            }
          else
            %{state | queue: new_queue}
          end

        # Determine actions related to pacing
        pacer_actions =
          if should_start_timer do
            [
              start_timer: {
                :pacer,
                @interval
              }
            ]
          else
            []
          end

        Membrane.Logger.info("response.audio.delta: should_start_timer: #{should_start_timer}")
        {pacer_actions, new_state}

      %{"type" => "response.audio.done"} ->
        # The stream is complete, nothing more to enqueue. The timer will stop when the queue empties.
        Membrane.Logger.info("Response audio stream ended.")
        now = :os.system_time(:millisecond)

        {[], state}

      %{"type" => "response.audio_transcript.done", "transcript" => transcript} ->
        Membrane.Logger.info("AI transcription: #{transcript}")
        {[], state}

      %{} ->
        Membrane.Logger.debug("Unhandled WS frame: #{frame}")
        {[], state}
    end
  end
end
