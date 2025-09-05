defmodule MembraneOpenAI.OpenAIEndpoint do
  use Membrane.Endpoint
  require Membrane.Logger

  def_input_pad(:input, accepted_format: _any)
  def_output_pad(:output, accepted_format: _any, flow_control: :push)

  def_options(websocket_opts: [])

  @impl true
  def handle_init(_ctx, opts) do
    {:ok, ws} = MembraneOpenAI.OpenAIWebSocket.start_link(opts.websocket_opts)

    {[], %{ws: ws}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    format = %Membrane.RawAudio{channels: 1, sample_rate: 24_000, sample_format: :s16le}
    {[stream_format: {:output, format}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    audio = Base.encode64(buffer.payload)
    frame = %{type: "input_audio_buffer.append", audio: audio} |> Jason.encode!()

    :ok =
      MembraneOpenAI.OpenAIWebSocket.send_frame(state.ws, frame)

    {[], state}
  end

  @impl true
  def handle_info({:websocket_frame, {:text, frame}}, _ctx, state) do
    case Jason.decode!(frame) do
      %{"type" => "response.audio.delta", "delta" => delta} ->
        audio_payload =
          Base.decode64!(delta)

        {[buffer: {:output, %Membrane.Buffer{payload: audio_payload}}], state}

      %{"type" => "response.audio.done"} ->
        {[event: {:output, %Membrane.Realtimer.Events.Reset{}}], state}

      %{"type" => "response.audio_transcript.done", "transcript" => transcript} ->
        Membrane.Logger.info("AI transcription: #{transcript}")
        {[], state}

      %{} ->
        {[], state}
    end
  end
end
