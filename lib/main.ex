defmodule Main do
  def main([num_nodes_string, topology, algorithm]) do
    num_nodes = String.to_integer(num_nodes_string)

    num_nodes =
      if topology == "3Dtorus" do
        trunc(:math.pow(Float.ceil(:math.pow(num_nodes, 1 / 3)), 3))
      else
        num_nodes
      end

    # IO.puts("#{num_nodes} #{topology} #{algorithm}")

    neighbors = Topology.getNeighbours(topology, num_nodes)

    # IO.inspect neighbors

    # IO.puts "Started things"

    if algorithm == "gossip" do
      gossip(num_nodes, neighbors)
    else
      push_sum(num_nodes, neighbors)
    end

    {:ok, self()}
  end

  defp gossip(num_nodes, neighbors) do
    Gossip.Supervisor.start_link()
    Gossip.Supervisor.start_state_server()

    start_time = System.monotonic_time(:millisecond)

    Enum.each(1..num_nodes, fn node_number ->
      Gossip.Supervisor.add_node(node_number, Enum.at(neighbors, node_number - 1))
    end)

    GenServer.cast(
      Gossip.Supervisor.worker_name(div(num_nodes, 2) + 1),
      {:handle_rumor, "This is the rumor"}
    )

    lets_wait(&Gossip.State.everyone_completed/0)
    end_time = System.monotonic_time(:millisecond)

    IO.inspect(DynamicSupervisor.which_children(:supervisor_for_node) |> length())

    state = Gossip.State.get_state()

    IO.puts(
      "Convergence Time is #{end_time - start_time} with workers ran #{
        state.initialized |> length()
      } with percentage #{(state.completed |> length()) / num_nodes * 100}"
    )
  end

  defp push_sum(num_nodes, neighbors) do
    PushSum.Supervisor.start_link()
    PushSum.Supervisor.start_state_server()

    Enum.each(1..num_nodes, fn node_number ->
      PushSum.Supervisor.add_node(node_number, Enum.at(neighbors, node_number - 1))
    end)

    start_time = System.monotonic_time(:millisecond)

    GenServer.cast(PushSum.Supervisor.worker_name(div(num_nodes, 2) + 1), {:push_sum, 0, 0})

    lets_wait(&PushSum.State.everyone_completed/0)
    end_time = System.monotonic_time(:millisecond)

    IO.inspect(DynamicSupervisor.which_children(:supervisor_for_node) |> length())

    state = PushSum.State.get_state()

    IO.puts(
      "Convergence Time is #{end_time - start_time} with workers ran #{
        state.initialized |> length()
      } with percentage #{(state.completed |> length()) / num_nodes * 100}"
    )
  end

  defp lets_wait(condition) do
    if condition.() do
      nil
    else
      lets_wait(condition)
    end
  end
end
