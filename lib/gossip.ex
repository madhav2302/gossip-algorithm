defmodule GossipWorker do
  use GenServer

  @interval 0
  @max_rumor_count 10

  def start_link(worker_name, neighbours) do
    GenServer.start_link(__MODULE__, [worker_name, neighbours], name: worker_name)
  end

  def init([worker_name, neighbours]) do
    {:ok,
     %{count: 0, neighbours: neighbours, worker_name: worker_name, scheduled_periodically: false}}
  end

  def handle_call({:fail_the_node}, _from, state) do
    {:stop, :normal, state, state}
  end

  def handle_cast({:handle_rumor, rumor}, state) do
    if state.count == 0 do
      State.init_worker(state.worker_name)
    end

    updated_state = Map.put(state, :count, state.count + 1)
    updated_state = Map.put(updated_state, :rumor, rumor)

    cond do
      updated_state.count == @max_rumor_count ->
        State.completed(updated_state.worker_name)
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
    neighbours = Enum.filter(state.neighbours, fn n ->
      pid = Process.whereis(n)
      if (pid == nil) do
        false
      else
        Process.alive?(pid)
      end
    end)

    state = Map.put(state, :neighbours, neighbours)

    if state.neighbours |> length() == 0 do
      State.no_more_neighbours(state.worker_name)
      {:stop, :normal, state}
    else
      # IO.puts("Count of #{state.worker_name} is #{state.count}")
      GenServer.cast(Enum.random(state.neighbours), {:handle_rumor, state.rumor})
      Process.send_after(self(), {:scheduled_periodically}, @interval)
      {:noreply, state}
    end
  end
end
