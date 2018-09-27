defmodule MASTER do
  use Application    #change to application later

  #def start_link(numNodes, topology, algorithm, mainProcessID) do
   # Supervisor.start_link(__MODULE__,[numNodes, topology, algorithm, mainProcessID])
  #end
  #def init([numNodes, topology, algorithm, mainProcessID]) do
   # children = [worker(SSUPERVISOR,[numNodes, topology, algorithm, mainProcessID],restart: :temporary)]
    #Supervisor.init(children, strategy: :one_for_one)
  #end
  #def start(_type,_args) do
    #SSUPERVISOR.start_link(name: SSupervisor)
  #end
end
