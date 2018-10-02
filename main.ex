defmodule MAIN do
  [numNodes,topology,algorithm] =Enum.map(System.argv, (fn(x) -> x end))
  numNodes = String.to_integer(numNodes)
  nodes = case topology do
    "torus" -> round(:math.pow(Float.ceil(:math.sqrt(numNodes)),2))
    "3D" -> round(:math.pow(Float.ceil(:math.pow(numNodes,(1/3))),3))
    _ -> numNodes
  end
  SSUPERVISOR.start_link(nodes)
  TOPOLOGIES.buildTopology(topology,nodes)
  case algorithm do
    "gossip" -> SERVER.startGossip("GossipMessage",System.os_time(:millisecond),nodes)
    "push-sum" ->  SERVER.startPushSum(nodes,System.monotonic_time(:millisecond))
    _ -> IO.puts "Invalid value of topology"
    System.halt(1)
  end
  Process.flag(:trap_exit, true)
end
