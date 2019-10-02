defmodule ProjSupervisor do
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
      start: {State, :start_link, []}
    })
  end

  def add_gossip_node(node_number, neighbors) do
    DynamicSupervisor.start_child(:supervisor_for_node, %{
      id: node_number,
      restart: :transient,
      start: {GossipWorker, :start_link, [worker_name(node_number), neighbors]}
    })
  end

  def add_push_sum_node(node_number, neighbors) do
    DynamicSupervisor.start_child(:supervisor_for_node, %{
      id: node_number,
      restart: :transient,
      start: {PushSumWorker, :start_link, [worker_name(node_number), node_number, neighbors]}
    })
  end

  def worker_name(node_number) do
    :"worker_#{node_number}"
  end
end
