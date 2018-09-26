defmodule SUPERVISOR do
  use Supervisor

 def start_link(numNodes) do
  Supervisor.start_link(__MODULE__,[numNodes])
 end

   #---------------- creating multiple genserver processes ---------------#

 def init([numNodes]) do
  children = Enum.map(1..numNodes, fn(x) ->
    worker(GOSSIP, [x], [id: x, restart: :permanent])
  end)
  {:ok, pid} = Supervisor.init(children, strategy: :one_for_one)
  IO.inspect pid
  #IO.inspect Supervisor.count_children(pid)
  #node_lists <- call network function to create neighbour array
  #function to pick a random pid and update its state to the value

 end
end
