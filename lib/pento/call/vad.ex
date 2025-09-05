defmodule MembraneOpenAI.VAD do
  use Membrane.Filter

  def_input_pad(:input,
    availability: :always,
    flow_control: :manual,
    demand_unit: :buffers,
    accepted_format: Membrane.RawAudio
  )

  def_output_pad(:output,
    availability: :always,
    flow_control: :manual,
    accepted_format: Membrane.RawAudio
  )

  @impl true
  def handle_init(_ctx, _mod) do
    # Need to use this older version: "https://raw.githubusercontent.com/snakers4/silero-vad/v4.0stable/files/silero_vad.onnx"
    model = Ortex.load("./silero_vad_likely.onnx")

    min_ms = 100

    # herz = per second
    # Match our Opus decoder's sample rate
    sample_rate_hz = 24000
    sr = Nx.tensor(sample_rate_hz, type: :s64)
    n_samples = min_ms * (sample_rate_hz / 1000)
    bytes_per_chunk = n_samples * 2

    init_state = %{
      h: Nx.broadcast(0.0, {2, 1, 64}),
      c: Nx.broadcast(0.0, {2, 1, 64}),
      n: 0,
      sr: sr
    }

    state = %{run_state: init_state, model: model, bytes: bytes_per_chunk, buffered: []}
    {[], state}
  end

  @impl true
  def handle_playing(_ctx, state) do
    {[demand: {:input, 1}], state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {[demand: {:input, size}], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: data} = buffer, _context, state) do
    %{n: n, sr: sr, c: c, h: h} = state.run_state
    buffered = [state.buffered, data]

    if IO.iodata_length(buffered) >= state.bytes do
      data = IO.iodata_to_binary(buffered)

      input =
        data
        |> Nx.from_binary(:s16)
        |> Nx.as_type(:f32)
        |> List.wrap()
        |> Nx.stack()

      {output, hn, cn} = Ortex.run(state.model, {input, sr, h, c})
      prob = output |> Nx.squeeze() |> Nx.to_number()

      IO.puts("Chunk ##{n}: #{Float.round(prob, 3)}")
      run_state = %{c: cn, h: hn, n: n + 1, sr: sr}
      state = %{state | run_state: run_state, buffered: []}

      if prob > 0.2 do
        {[demand: {:input, 1}, buffer: {:output, buffer}], state}
      else
        buffer_size = byte_size(buffer.payload) * 8

        {[demand: {:input, 1}, buffer: {:output, %{buffer | payload: <<0::size(buffer_size)>>}}],
         state}
      end
    else
      %{state | buffered: buffered}
      {[demand: {:input, 1}], state}
    end
  end
end
