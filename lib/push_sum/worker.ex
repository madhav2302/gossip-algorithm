defmodule PushSum.Worker do
  use GenServer

  @interval 0
  @actor_ratio_threshold :math.pow(10, -10)

  def start_link(worker_name, worker_number, neighbours) do
    GenServer.start_link(__MODULE__, [worker_name, worker_number, neighbours], name: worker_name)
  end

  def init([worker_name, worker_number, neighbours]) do
    {:ok,
     %{
       neighbours: neighbours,
       worker_name: worker_name,
       scheduled_periodically: false,
       s: worker_number,
       w: 1,
       ratio: worker_number / 1,
       changes: 0
     }}
  end

  def handle_cast({:push_sum, s_from, w_from}, state) do
    state =
      if state.scheduled_periodically == false do
        PushSum.State.init_worker(state.worker_name)
        Process.send_after(self(), {:scheduled_periodically}, @interval)
        Map.put(state, :scheduled_periodically, true)
      else
        state
      end

    s_new = state.s + s_from
    w_new = state.w + w_from
    ratio_new = s_new / w_new
    ratio_diff = ratio_new - state.ratio
    ratio_diff = abs(ratio_diff)

    {changes, stop} =
      if(ratio_diff < @actor_ratio_threshold && state.changes == 2) do
        PushSum.State.completed(state.worker_name, ratio_new)
        {state.changes, true}
      else
        if(ratio_diff < @actor_ratio_threshold) do
          {state.changes + 1, false}
        else
          {0, false}
        end
      end

    state = Map.put(state, :s, s_new)
    state = Map.put(state, :w, w_new)
    state = Map.put(state, :ratio, ratio_new)
    state = Map.put(state, :changes, changes)

    if stop do
      {:stop, :normal, state}
    else
      {:noreply, state}
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
      PushSum.State.no_more_neighbours(state.worker_name, state.ratio)
      {:stop, :normal, state}
    else
      # IO.puts("Count of #{state.worker_name} is #{state.count}")
      GenServer.cast(Enum.random(state.neighbours), {:push_sum, state.s, state.w})
      Process.send_after(self(), {:scheduled_periodically}, @interval)
      {:noreply, state}
    end
  end
end
