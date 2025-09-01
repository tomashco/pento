defmodule MembraneOpenAI.Pipeline do
  use Membrane.Pipeline

  def start_link(opts) do
    Membrane.Pipeline.start_link(__MODULE__, opts)
  end

  @impl true
  def handle_init(_ctx, opts) do
    require Membrane.Logger

    Membrane.Logger.info(
      "Initializing MembraneOpenAI.Pipeline with source_channel: #{inspect(opts[:source_channel])} and sink_channel: #{inspect(opts[:sink_channel])}"
    )

    openai_api_key = Application.get_env(:pento, :openai_api_key)

    openai_ws_opts = [
      extra_headers: [
        {"Authorization", "Bearer " <> openai_api_key},
        {"OpenAI-Beta", "realtime=v1"}
      ]
    ]

    spec = [
      # Input path: Mic → OpenAI
      child(:webrtc_source, %Membrane.WebRTC.Source{
        signaling: opts[:source_channel]
      })
      |> via_out(:output, options: [kind: :audio])
      |> child(:input_opus_parser, Membrane.Opus.Parser)
      |> child(:opus_decoder, %Membrane.Opus.Decoder{sample_rate: 24_000})
      # |> child(:vad, MembraneOpenAI.VAD)
      |> child(:open_ai, %MembraneOpenAI.OpenAIEndpoint{websocket_opts: openai_ws_opts}),

      # Output path: OpenAI → Browser
      get_child(:open_ai)
      |> via_out(:output)
      |> child(:raw_audio_parser, %Membrane.RawAudioParser{overwrite_pts?: true})
      |> child(:realtimer, Membrane.Realtimer)
      |> child(:opus_encoder, Membrane.Opus.Encoder)
      |> via_in(:input, options: [kind: :audio])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        tracks: [:audio],
        signaling: opts[:sink_channel]
      })
    ]

    Membrane.Logger.info("Pipeline spec created with #{length(spec)} elements")

    {[spec: spec], %{}}
  end
end
