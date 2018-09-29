defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(10,"line","gossip") #name: SSupervisor
  GOSSIP.buildTopology("imp2D",10)
  GOSSIP.startGossip("gossip",1,self(),10)

  #MASTER.start(1,2)
  #MASTER.start_link(numNodes, topology, algo, self())
end
