defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(10000,"line","gossip") #name: SSupervisor
  GOSSIP.buildTopology("rand2D",10000)
  #MASTER.start(1,2)
  #MASTER.start_link(numNodes, topology, algo, self())
end
