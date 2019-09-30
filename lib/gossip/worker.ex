defmodule Gossip.Worker do
  use GenServer

  @interval 0
  @max_rumor_time 10

  def start_link(worker_name, neighbours) do
    GenServer.start_link(__MODULE__, [worker_name, neighbours], name: worker_name)
  end

  def init([worker_name, neighbours]) do
    {:ok,
     %{count: 0, neighbours: neighbours, worker_name: worker_name, scheduled_periodically: false}}
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:delete_neighbour, worker_name}, state) do
    updated_state = Map.put(state, :neighbours, state.neighbours -- [worker_name])
    # IO.puts("New neighbours of #{state.worker_name} are #{inspect(state.neighbours)}")
    {:noreply, updated_state}
  end

  def handle_cast({:handle_rumor}, state) do
    if state.count == 0 do
      Gossip.State.init_worker(state.worker_name)
    end

    updated_state = Map.put(state, :count, state.count + 1)

    cond do
      updated_state.count == @max_rumor_time ->
        Gossip.State.completed(updated_state.worker_name)

        Enum.each(updated_state.neighbours, fn neighbour ->
          GenServer.cast(neighbour, {:delete_neighbour, state.worker_name})
        end)

        {:stop, :normal, updated_state}

      state.scheduled_periodically == false ->
        Process.send_after(self(), {:scheduled_periodically}, @interval)
        updated_state = Map.put(updated_state, :scheduled_periodically, true)
        {:noreply, updated_state}

      true ->
        {:noreply, updated_state}
    end
  end

  def handle_info({:scheduled_periodically}, state) do
    terminated_workers = Gossip.State.terminated_workers()
    state = Map.put(state, :neighbours, state.neighbours -- terminated_workers)

    if state.neighbours |> length() == 0 do
      Gossip.State.no_more_neighbours(state.worker_name)
      {:stop, :normal, state}
    else
      # IO.puts("Count of #{state.worker_name} is #{state.count}")
      GenServer.cast(Enum.random(state.neighbours), {:handle_rumor})
      Process.send_after(self(), {:scheduled_periodically}, @interval)
      {:noreply, state}
    end
  end
end
