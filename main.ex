defmodule MAIN do
  [numNodes,topology,algorithm] =Enum.map(System.argv, (fn(x) -> x end))
  numNodes = String.to_integer(numNodes)
  SSUPERVISOR.start_link(numNodes)
  nodes = case topology do
    "torus" -> round(:math.pow(Float.floor(:math.sqrt(numNodes)),2))
    "3D" -> round(:math.pow(Float.floor(:math.pow(numNodes,(1/3))),3))
    _ -> numNodes
  end
  TOPOLOGIES.buildTopology(topology,nodes)
  case algorithm do
    "gossip" -> SERVER.startGossip("GossipMessage",System.monotonic_time(:millisecond),self(),nodes)
    "push-sum" ->  SERVER.startPushSum(nodes,System.monotonic_time(:millisecond))
    _ -> IO.puts "Invalid value of topology"
    System.halt(1)
  end
  Process.flag(:trap_exit, true)
end
