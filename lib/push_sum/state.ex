defmodule PushSum.State do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{initialized: [], completed: [], no_more_neighbours: []}}
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def initialized_length() do
    state = get_state()
    state.initialized |> length()
  end

  def everyone_completed() do
    state = get_state()

    if state.initialized |> length == 0 do
      false
    else
      (state.initialized -- (state.completed ++ state.no_more_neighbours)) |> length == 0
    end
  end

  def terminated_workers() do
    state = get_state()

    state.completed ++ state.no_more_neighbours
  end

  #### State manipulation mathods ####
  def init_worker(worker_name) do
    # IO.puts("#{worker_name} initialized")
    GenServer.call(__MODULE__, {:init, worker_name})
  end

  def completed(worker_name, ratio) do
    # IO.puts("#{worker_name} completed")
    IO.puts "Ratio from #{worker_name} is #{ratio} with completed"
    GenServer.cast(__MODULE__, {:completed, worker_name})
  end

  def no_more_neighbours(worker_name, ratio) do
    IO.puts "Ratio fro #{worker_name} is #{ratio} with no neighbour"
    # IO.puts("#{worker_name} no neighbours left")
    GenServer.cast(__MODULE__, {:no_more_neighbour, worker_name})
  end

  #### Callbacks ####
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:init, worker_name}, _from, state) do
    updated_state = Map.put(state, :initialized, state.initialized ++ [worker_name])
    {:reply, updated_state, updated_state}
  end

  def handle_cast({:completed, worker_name}, state) do
    updated_state = Map.put(state, :completed, state.completed ++ [worker_name])
    {:noreply, updated_state}
  end

  def handle_cast({:no_more_neighbour, worker_name}, state) do
    updated_state = Map.put(state, :no_more_neighbours, state.no_more_neighbours ++ [worker_name])
    {:noreply, updated_state}
  end
end
