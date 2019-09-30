defmodule Main do
  def main([num_nodes_string]) do
    num_nodes = String.to_integer(num_nodes_string)

    Gossip.Supervisor.start_link()
    Gossip.Supervisor.start_state_server()

    start_time = System.monotonic_time(:millisecond)

    Enum.each(1..num_nodes, fn node_number ->
      Gossip.Supervisor.add_node(node_number, num_nodes)
      GenServer.cast(Gossip.Supervisor.worker_name(node_number), {:handle_rumor, "This is the rumor"})
    end)

    lets_wait()
    end_time = System.monotonic_time(:millisecond)

    IO.puts("Convergence Time is #{end_time - start_time}")

    {:ok, self()}
  end

  defp lets_wait() do
    if Gossip.State.everyone_completed() do
      nil
    else
      lets_wait()
    end
  end
end
