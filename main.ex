defmodule MAIN do
  Process.flag(:trap_exit, true)
  SSUPERVISOR.start_link(1000,"full","gossip") #name: SSupervisor
  TOPOLOGIES.buildTopology("torus",25)
 #SERVER.startGossip("p",System.monotonic_time(:millisecond),self(),100)
  SERVER.startPushSum(25,System.monotonic_time(:millisecond))
end
