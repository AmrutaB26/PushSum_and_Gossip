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
    state=[count,[list |blist],s,w]
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
    map = Map.new()
    #table = :ets.new(:buckets_registry, [:set, :protected])
    map =Enum.reduce(1..numNodes,map, fn x,acc->
      node = String.to_atom("Child_"<>Integer.to_string(x))
      coordinates = {(Enum.random(0..1000*10)/10000),(Enum.random(0..1000*10)/10000)}
      #:ets.insert(table,{node,coordinates})
      Map.put(acc,node,coordinates)
      #IO.inspect acc
    end)
    IO.inspect is_map(map)
    get2DNeighbours(map)
    #IO.inspect generateRandomNumbers(numNodes,[])
  end

  #TODO-----------------------------------------------------------------------

  defp get2DNeighbours(list) do
    Map.keys(list)
    |> Enum.each(fn(x)->
      {refx, refy} = Map.fetch!(list,x)
      temp = Map.delete(list,x)
      keys = Map.keys(temp)
      Enum.each(keys, fn(y) ->
        {coorx,coory} = Map.fetch!(temp,y)
        if(:math.sqrt(:math.pow((refx-coorx),2) + :math.pow((refy-coory),2)) < 0.1) do
          updateNeighbours(x, y)
        end
      end)

      #IO.inspect refx
    end)
    #Enum.each(list, fn({k,a}) ->
      #{refx, refy} = Map.fetch!(list,x)

    #end)

    #elements = Float.floor(0.1/(1/sqroot))
  #  Enum.each(list, fn(k) ->
   #   index=Enum.find_index(list, fn(x) -> x==k end)
    #  IO.inspect index
      #Enum.map(, fn(x) ->
      #  neighbours = [neighbours | "Child_"<>Integer.to_string(Enum.fetch!(list,index+(sqroot*(x+1))))]
      # updateNeighbours(String.to_atom("Child_"<>Integer.to_string(k)), neighbours)
      #end)
    #end)
  end
end

