defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       score: 10,
       message: "Make a guess:",
       solution: solution(),
       is_winning?: false
     )}
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    if guess == socket.assigns.solution |> to_string() do
      message =
        "Your guess: #{guess}. Correct. You win!"

      score = socket.assigns.score + 1

      {:noreply, assign(socket, message: message, score: score, is_winning?: true)}
    else
      message =
        "Your guess: #{guess}. Wrong. Guess again. "

      # {guess} == #{socket.assigns.solution |> to_string()}"

      score = socket.assigns.score - 1
      {:noreply, assign(socket, message: message, score: score, is_winning?: false)}
    end
  end

  def handle_event("restart", _params, socket) do
    {:noreply,
     assign(socket,
       score: 10,
       message: "Make a guess:",
       solution: solution(),
       is_winning?: false
     )}
  end

  def solution() do
    :rand.uniform(9)
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <h1 class="text-4xl font-extrabold">Your score: <%= @score %></h1>
      <h2>
        <%= @message %>
      </h2>
      <br />
      <h2>
        <%= for n <- 1..10 do %>
          <.link
            class="bg-blue-500 hover:bg-blue-700
          text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
            phx-click="guess"
            phx-value-number={n}
          >
            <%= n %>
          </.link>
        <% end %>
      </h2>
      <%= if @is_winning? do %>
        <p class="mt-4">You win!</p>
        <p>Your score: <%= @score %></p>
        <.link
          class="bg-blue-500 hover:bg-blue-700
        text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
          phx-click="restart"
        >
          Play again!
        </.link>
      <% end %>
    </div>
    """
  end
end
