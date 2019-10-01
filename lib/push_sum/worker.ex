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
      end

    s = state.s + s_from
    w = state.w + w_from
    s_new = s / 2
    w_new = w / 2
    ratio_new = s_new / w_new
    ratio_diff = ratio_new - state.ratio
    ratio_diff = abs(ratio_diff)

    {changes, stop} =
      if(ratio_diff < @actor_ratio_threshold && state.changes == 2) do
        PushSum.State.completed(state.worker_name)
        {state.changes, true}
      else
        if(ratio_diff < @actor_ratio_threshold) do
          {state.changes + 1, false}
        else
          {0, false}
        end
      end

    updated_state = Map.put(state, :s, s_new)
    updated_state = Map.put(updated_state, :w, w_new)
    updated_state = Map.put(updated_state, :ratio, ratio_new)
    updated_state = Map.put(updated_state, :changes, changes)

    if stop do
      {:stop, :normal, updated_state}
    else
      {:noreply, updated_state}
    end
  end

  def handle_info({:scheduled_periodically}, state) do
    terminated_workers = PushSum.State.terminated_workers()
    state = Map.put(state, :neighbours, state.neighbours -- terminated_workers)

    if state.neighbours |> length() == 0 do
      PushSum.State.no_more_neighbours(state.worker_name)
      {:stop, :normal, state}
    else
      # IO.puts("Count of #{state.worker_name} is #{state.count}")
      GenServer.cast(Enum.random(state.neighbours), {:push_sum, state.rumor})
      Process.send_after(self(), {:scheduled_periodically}, @interval)
      {:noreply, state}
    end
  end
end
