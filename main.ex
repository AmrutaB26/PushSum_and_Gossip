defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(1000,"full","gossip") #name: SSupervisor
  TOPOLOGIES.buildTopology("rand2D",1000)
 #SERVER.startGossip("p",System.monotonic_time(:millisecond),self(),100)
  SERVER.startPushSum(1000,System.monotonic_time(:millisecond))
end
