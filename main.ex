defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(10000,"full","gossip") #name: SSupervisor
  TOPOLOGIES.buildTopology("full",100)
 SERVER.startGossip("p",System.monotonic_time(:millisecond),self(),100)
#SERVER.startPushSum(100,System.monotonic_time(:millisecond))
  #MASTER.start(1,2)
  #MASTER.start_link(numNodes, topology, algo, self())
end
