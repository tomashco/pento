defmodule PentoWeb.StreamSenderLive do
  use PentoWeb, :live_view

  alias Membrane
  alias WebRTC

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        ingress_signaling = Membrane.WebRTC.Signaling.new()
        egress_signaling = Membrane.WebRTC.Signaling.new()

        Membrane.Pipeline.start_link(WebRTC.Pipeline,
          ingress_signaling: ingress_signaling,
          egress_signaling: egress_signaling
        )

        socket
        |> Membrane.WebRTC.Live.Capture.attach(
          id: "mediaCapture",
          signaling: ingress_signaling,
          video?: true,
          audio?: false,
          preview?: false
        )
        |> Membrane.WebRTC.Live.Player.attach(
          id: "videoPlayer",
          signaling: egress_signaling
        )
      else
        socket
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Membrane.WebRTC.Live.Capture.live_render socket={@socket} capture_id="mediaCapture" />
    <Membrane.WebRTC.Live.Player.live_render socket={@socket} player_id="videoPlayer" />
    """
  end
end
