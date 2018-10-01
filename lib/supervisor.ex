defmodule SSUPERVISOR do
  use Supervisor

 def start_link(numNodes) do
  Supervisor.start_link(__MODULE__,[numNodes,self()], name: __MODULE__)
 end

   #---------------- creating multiple genserver processes ---------------#

 def init(args) do
  children = Enum.map(1..hd(args), fn(x) ->
    worker(SERVER, [x], [id: x, restart: :temporary])
  end)
  Supervisor.init(children, strategy: :one_for_one)
 end
end
