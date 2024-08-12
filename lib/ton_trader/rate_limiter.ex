defmodule TonTrader.RateLimiter do
  @moduledoc """
  TON Api allows only 1 request per second. This module is responsible for rate limiting.
  """
  use GenServer

  @opaque queue_entry :: {pid(), Finch.Request.t()}

  @empty_queue :queue.new()

  defmodule State do
    defstruct [:queue, :timer_ref]
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def request(%Finch.Request{} = request) do
    GenServer.call(__MODULE__, {:request, request}, :infinity)
  end

  def init(queue) do
    state = %State{queue: :queue.from_list(queue)}

    {:ok, state, {:continue, :make_request}}
  end

  def handle_continue(:make_request, %State{queue: @empty_queue} = state) do
    {:noreply, state}
  end

  def handle_continue(:make_request, %State{queue: queue}) do
    {{:value, {from, request}}, rest_of_the_queue} = :queue.out(queue)

    case Finch.request(request, TonTrader.Finch, request_timeout: 3000) do
      {:ok, %Finch.Response{status: 429}} ->
        ref = Process.send_after(self(), :continue, 1000)

        {:noreply, %State{queue: queue, timer_ref: ref}}

      {:error, %Mint.TransportError{}} ->
        ref = Process.send_after(self(), :continue, 1000)

        {:noreply, %State{queue: queue, timer_ref: ref}}

      request_result ->
        :ok = GenServer.reply(from, request_result)

        ref = Process.send_after(self(), :continue, 1000)

        {:noreply, %State{queue: rest_of_the_queue, timer_ref: ref}}
    end
  end

  def handle_info(:continue, state) do
    {:noreply, state, {:continue, :make_request}}
  end

  def handle_call({:request, request}, from, %State{queue: old_queue, timer_ref: t}) do
    :ok = maybe_cancel_ref(t)
    new_queue = :queue.in({from, request}, old_queue)
    new_ref = Process.send_after(self(), :continue, 1000)

    {:noreply, %State{queue: new_queue, timer_ref: new_ref}}
  end

  defp maybe_cancel_ref(nil), do: :ok

  defp maybe_cancel_ref(ref) when is_reference(ref) do
    Process.cancel_timer(ref)

    :ok
  end
end
