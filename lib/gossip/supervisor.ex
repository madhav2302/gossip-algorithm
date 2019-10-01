defmodule Gossip.Supervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: :supervisor_for_node)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_state_server() do
    DynamicSupervisor.start_child(:supervisor_for_node, %{
      id: :state_server,
      start: {Gossip.State, :start_link, []}
    })
  end

  def add_node(node_number, neighbors) do
    DynamicSupervisor.start_child(:supervisor_for_node, %{
      id: node_number,
      restart: :transient,
      start: {Gossip.Worker, :start_link, [worker_name(node_number), neighbors]}
    })
  end

  def worker_name(node_number) do
    :"worker_#{node_number}"
  end
end
