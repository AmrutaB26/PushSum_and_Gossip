defmodule GOSSIP do
  use GenServer

  ## ----------- Callback functions ------------- ##

  def start_link(num) do
    GenServer.start_link(__MODULE__,[0,[],0,1], name: String.to_atom("Child_"<>Integer.to_string(num)))
  end
  def init(args) do
    Process.flag(:trap_exit, true)
    {:ok, args}
  end
  def handle_cast({:neighboursList,list}, state) do
    [count,blist,s,w]=state
    state=[count,list,s,w]
    {:noreply, state}
  end
  def handle_call({:neighboursList}, _from, state) do
    {:reply,state, state}
  end

  ## --------------- CLient API ---------------- ##

  def updateNeighbours(id,list) do
    GenServer.cast(id,{:neighboursList, list})
  end
  def getNeighbours(id) do
    IO.inspect GenServer.call(id,{:neighboursList})
  end

  def buildTopology(newTopology,numNodes) do
    case newTopology do
      "full" -> buildFullTopology(numNodes)
      #"3D" -> build3DTopology(numNodes)
      "rand2D" -> buildRand2DTopology(numNodes)
     # "sphere" -> buildSphereTopology(numNodes)
      "line" -> buildLineTopology(numNodes)
    #  "imp2D" -> buildimp2DTopology(numNodes)
      _ -> IO.puts "Invalid value of topology"
    end
    Enum.map(1..numNodes, fn(x) -> getNeighbours(String.to_atom("Child_"<>Integer.to_string(x))) end)
  end
  def buildLineTopology(numNodes) do
    Enum.each(1..numNodes, fn(x) ->
      neighbour = cond do
        x==1 ->
          ["Child_"<>Integer.to_string(x+1)]
        x==numNodes ->
          ["Child_"<>Integer.to_string(x-1)]
        true->
          [("Child_"<>Integer.to_string(x-1)) , ("Child_"<>Integer.to_string(x+1))]
        end
        updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), neighbour)
    end)
  end

  def buildFullTopology(numNodes) do
    list=Enum.map(1..numNodes, fn(x)-> "Child_"<>Integer.to_string(x) end)
    Enum.each(1..numNodes, fn(x)->
      updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), List.delete(list,"Child_"<>Integer.to_string(x))) end)
  end
  def buildRand2DTopology(numNodes) do
    list=Enum.map(1..numNodes, fn(x)-> x end)
    list = Enum.shuffle(list)
    IO.inspect list
    sqroot = :math.sqrt(numNodes)

    #neighbours = [neighbours | getNeighbours()]
  end

  defp getNeighbours() do

  end
end

