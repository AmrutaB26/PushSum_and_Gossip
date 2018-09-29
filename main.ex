defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(100,"line","gossip") #name: SSupervisor
  GOSSIP.buildTopology("torus",16)
  #MASTER.start(1,2)
  #MASTER.start_link(numNodes, topology, algo, self())
end
