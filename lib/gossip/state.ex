defmodule Gossip.State do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    # send(self(), {:print_state_length})
    {:ok, %{initialized: [], completed: [], no_more_neighbours: []}}
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state, :infinity)
  end

  def everyone_completed() do
    state = get_state()

    if state.initialized == [] do
      false
    else
      (state.initialized -- (state.completed ++ state.no_more_neighbours)) |> length == 0
    end
  end

  #### State manipulation mathods ####
  def init_worker(worker_name) do
    # IO.puts("#{worker_name} initialized")
    GenServer.cast(__MODULE__, {:init, worker_name})
  end

  def completed(worker_name) do
    # IO.puts("#{worker_name} completed")
    GenServer.cast(__MODULE__, {:completed, worker_name})
  end

  def no_more_neighbours(worker_name) do
    # IO.puts("#{worker_name} no neighbours left")
    GenServer.cast(__MODULE__, {:no_more_neighbour, worker_name})
  end

  #### Callbacks ####
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:init, worker_name}, state) do
    updated_state = Map.put(state, :initialized, state.initialized ++ [worker_name])
    {:noreply, updated_state}
  end

  def handle_cast({:completed, worker_name}, state) do
    updated_state = Map.put(state, :completed, state.completed ++ [worker_name])
    {:noreply, updated_state}
  end

  def handle_cast({:no_more_neighbour, worker_name}, state) do
    updated_state = Map.put(state, :no_more_neighbours, state.no_more_neighbours ++ [worker_name])
    {:noreply, updated_state}
  end

  def handle_info({:print_state_length}, state) do
    # IO.puts(
    #   "Completed #{state.completed |> length()}, Initialized #{state.initialized |> length()}, no more neighbors #{
    #     state.no_more_neighbours |> length()
    #   }"
    # )

    IO.puts "Length is #{(state.initialized -- (state.completed ++ state.no_more_neighbours)) |> length}"
    # IO.inspect (state.initialized -- (state.completed ++ state.no_more_neighbours))

    Process.send_after(self(), {:print_state_length}, 1)

    {:noreply, state}
  end
end
