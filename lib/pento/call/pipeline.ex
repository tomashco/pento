defmodule Pento.Call.Pipeline do
  use Membrane.Pipeline
  alias Pento.DeepgramEndpoint

  def start_link(opts) do
    Membrane.Pipeline.start_link(__MODULE__, opts)
  end

  @impl true
  def handle_init(_ctx, opts) do
    require Membrane.Logger

    # Determine which AI service to use
    stt_service = opts[:stt_service] || :openai

    Membrane.Logger.info(
      "Initializing Pento.Call.Pipeline with source_channel: #{inspect(opts[:source_channel])}, sink_channel: #{inspect(opts[:sink_channel])}, stt_service: #{stt_service}"
    )

    spec =
      case stt_service do
        :deepgram -> build_deepgram_spec(opts)
        :openai -> build_openai_spec(opts)
        _ -> raise "Unsupported AI service: #{stt_service}"
      end

    Membrane.Logger.info("Pipeline spec created with #{length(spec)} elements")

    {[spec: spec], %{}}
  end

  defp build_deepgram_spec(opts) do
    [
      # Input path: Mic → Deepgram
      child(:webrtc_source, %Membrane.WebRTC.Source{
        signaling: opts[:source_channel]
      })
      |> via_out(:output, options: [kind: :audio])
      |> child(:input_opus_parser, Membrane.Opus.Parser)
      |> child(:opus_decoder, %Membrane.Opus.Decoder{sample_rate: 16_000})
      # |> child(:vad, Pento.Call.VAD)

      # Deepgram endpoint for transcription only
      |> child(:deepgram, %DeepgramEndpoint{websocket_opts: []})
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
  end

  defp build_openai_spec(opts) do
    openai_api_key = Application.get_env(:pento, :openai_api_key)

    openai_ws_opts = [
      extra_headers: [
        {"Authorization", "Bearer " <> openai_api_key},
        {"OpenAI-Beta", "realtime=v1"}
      ]
    ]

    [
      # Input path: Mic → OpenAI
      child(:webrtc_source, %Membrane.WebRTC.Source{
        signaling: opts[:source_channel]
      })
      |> via_out(:output, options: [kind: :audio])
      |> child(:input_opus_parser, Membrane.Opus.Parser)
      |> child(:opus_decoder, %Membrane.Opus.Decoder{sample_rate: 24_000})

      # Output path: OpenAI → Browser
      |> child(:open_ai, %MembraneOpenAI.OpenAIEndpoint{websocket_opts: openai_ws_opts})
      |> child(:raw_audio_parser, %Membrane.RawAudioParser{overwrite_pts?: true})
      |> child(:opus_encoder, Membrane.Opus.Encoder)
      |> via_in(:input, options: [kind: :audio])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        tracks: [:audio],
        signaling: opts[:sink_channel]
      })
    ]
  end
end
