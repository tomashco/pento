defmodule Membrane.BufferDiscarder.Events.Flush do
  @moduledoc """
  Event used to flush all queued buffers in BufferDiscarder.
  """
  @derive Membrane.EventProtocol
  defstruct []
end
