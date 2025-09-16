defmodule Pento.DeepgramEndpoint do
  use Membrane.Endpoint
  require Membrane.Logger

  def_input_pad(:input, accepted_format: _any)
  def_output_pad(:output, accepted_format: _any, flow_control: :push)

  def_options(websocket_opts: [])

  @impl true
  def handle_init(_ctx, opts) do
    # Get API key from options or application config
    api_key = Application.get_env(:pento, :deepgram_api_key)

    # Create Deepgram client
    client = Deepgram.new(api_key: api_key)

    {:ok, websocket} =
      Deepgram.Listen.live_transcription(
        client,
        %{
          model: "nova-2",
          interim_results: true,
          punctuate: true,
          encoding: "linear16",
          sample_rate: 16000,
          channels: 1
        }
      )

    {[], %{websocket: websocket, client: client}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    format = %Membrane.RawAudio{channels: 1, sample_rate: 16_000, sample_format: :s16le}
    {[stream_format: {:output, format}], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    # Deepgram expects raw audio data, not base64 encoded
    # Membrane.Logger.debug("Sending buffer of size #{byte_size(buffer.payload)}")
    :ok = Deepgram.Listen.WebSocket.send_audio(state.websocket, buffer.payload)
    {[], state}
  end

  @impl true
  def handle_info({:deepgram_result, %{"type" => "Results"} = result}, _ctx, state) do
    # IO.inspect(result, label: "Deepgram full result")

    alt = hd(result["channel"]["alternatives"])
    transcript = alt["transcript"]

    # if transcript != "" do
    if result["is_final"] do
      Membrane.Logger.info("Deepgram final transcript: #{transcript}")
    else
      Membrane.Logger.debug("Deepgram interim: #{transcript}")
    end

    # end

    {[], state}
  end

  def handle_info({:deepgram_metadata, metadata}, _ctx, state) do
    Membrane.Logger.debug("Deepgram metadata: #{inspect(metadata)}")
    {[], state}
  end

  def handle_info({:deepgram_utterance_end, msg}, _ctx, state) do
    Membrane.Logger.info("Deepgram utterance ended: #{inspect(msg)}")
    {[], state}
  end

  def handle_info({:deepgram_speech_started, msg}, _ctx, state) do
    Membrane.Logger.debug("Deepgram speech started: #{inspect(msg)}")
    {[], state}
  end

  def handle_info({:deepgram_error, error}, _ctx, state) do
    Membrane.Logger.error("Deepgram error: #{inspect(error)}")
    {[], state}
  end

  def handle_info(other, _ctx, state) do
    Membrane.Logger.debug("Unhandled Deepgram message: #{inspect(other)}")
    {[], state}
  end

  @impl true
  def handle_terminate(_ctx, state) do
    # Clean up WebSocket connection
    if state.websocket do
      Deepgram.Listen.WebSocket.close(state.websocket)
    end

    :ok
  end
end
