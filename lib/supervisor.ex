defmodule SSUPERVISOR do
  use Supervisor

 def start_link(numNodes,topology,algorithm) do
  Supervisor.start_link(__MODULE__,[numNodes,topology,algorithm,self()], name: __MODULE__)
 end

   #---------------- creating multiple genserver processes ---------------#

 def init(args) do #[numNodes,topology,algorithm,pid]
  children = Enum.map(1..hd(args), fn(x) ->
    worker(GOSSIP, [x], [id: x, restart: :temporary])
  end)
  IO.puts "Children created"
  Supervisor.init(children, strategy: :one_for_one)
  #node_lists <- call network function to create neighbour array
  #function to pick a random pid and update its state to the value
 end
end
