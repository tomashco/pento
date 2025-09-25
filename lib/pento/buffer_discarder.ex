defmodule Membrane.BufferDiscarder do
  use Membrane.Filter

  alias Membrane.Buffer
  alias Membrane.Event
  alias Membrane.BufferDiscarder.Events.Flush

  def_input_pad(:input,
    accepted_format: _any,
    flow_control: :manual,
    demand_unit: :buffers
  )

  def_output_pad(:output,
    accepted_format: _any,
    flow_control: :manual,
    demand_unit: :buffers
  )

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{queue: :queue.new()}}
  end

  @impl true
  def handle_buffer(:input, %Buffer{} = buffer, _ctx, state) do
    Membrane.Logger.info(
      "Receiving buffer with PTS: #{buffer.pts}, buffer length: #{:queue.len(state.queue)}"
    )

    {[], %{state | queue: :queue.in(buffer, state.queue)}}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    Membrane.Logger.info("Requesting chunk from realtimer, size: #{size}")

    {to_send, rest} = take_from_queue(state.queue, size)

    actions =
      if to_send == [] do
        [demand: {:input, size}]
      else
        Membrane.Logger.info("Sending buffers. First buffer's PTS: #{hd(to_send).pts}")
        [buffer: {:output, to_send}]
      end

    Membrane.Logger.info("actions: #{inspect(actions)} rest: #{inspect(rest)}")

    {actions, %{state | queue: rest}}
  end

  @impl true
  def handle_event(:input, %Flush{}, _ctx, _state) do
    Membrane.Logger.info("Flushing buffers from internal state")
    {[], %{queue: :queue.new()}}
  end

  @impl true
  def handle_event(_pad, event, _ctx, state) do
    {[forward: event], state}
  end

  defp take_from_queue(queue, count) do
    do_take(queue, count, [])
  end

  defp do_take(queue, 0, acc), do: {Enum.reverse(acc), queue}

  defp do_take(queue, n, acc) do
    case :queue.out(queue) do
      {{:value, buf}, rest} -> do_take(rest, n - 1, [buf | acc])
      {:empty, _} -> {Enum.reverse(acc), queue}
    end
  end
end
