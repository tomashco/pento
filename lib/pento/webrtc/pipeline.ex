defmodule WebRTC.Pipeline do
  use Membrane.Pipeline

  @webrtc_h264 %Membrane.H264{alignment: :nalu, stream_structure: :annexb}

  @impl true
  def handle_init(_ctx, opts) do
    spec =
      child(:webrtc_source, %Membrane.WebRTC.Source{
        allowed_video_codecs: :h264,
        signaling: opts[:ingress_signaling]
      })
      |> via_out(:output, options: [kind: :video])
      |> child(%Membrane.Transcoder{output_stream_format: Membrane.RawVideo})
      |> child(%Membrane.FFmpeg.SWScale.Converter{format: :RGB})
      |> child(WebRTCLiveView.CountoursDrawer)
      |> child(%Membrane.FFmpeg.SWScale.Converter{format: :I420})
      |> child(%Membrane.Transcoder{output_stream_format: @webrtc_h264})
      |> via_in(:input, options: [kind: :video])
      |> child(:webrtc_sink, %Membrane.WebRTC.Sink{
        video_codec: :h264,
        signaling: opts[:egress_signaling]
      })

    {[spec: spec], %{}}
  end
end
