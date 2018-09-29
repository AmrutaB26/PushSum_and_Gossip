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

  def handle_call({:updateStateCount,msg,startTime,parent,numNodes}, _from, state) do
    [count,blist,s,w,message]=state
    state=[count+1,blist,s,w,message]
    neighpid=String.to_atom(getRandomAliveNeighbour(blist))
    Task.start(recursiveGossip(neighpid,msg,startTime,parent,numNodes))
    {:reply,Enum.at(state,4), state}
  end

  def handle_call({:terminate,msg,pid,parent,numNodes,startTime}, _from, state) do
    if(Enum.at(state,0)>10) do
      :ets.update_counter(:table,"killedProcess",{2,1})
      Process.exit(pid,:kill)
      [{_,count}]=:ets.lookup(:table,"killedProcess")
      if(count>=numNodes) do
        endTime=System.monotonic_time(:millisecond)
        IO.puts("Convergence reached at #{inspect (endTime-startTime) }")
        Process.exit(parent,:kill)
      end
    else
      recursiveGossip(pid,msg,startTime,parent,numNodes)
    end
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

  def getRandomAliveNeighbour(list) do
    neighbourNode=Enum.random(list)
    if(!Process.alive?(neighbourNode)) do
      getRandomAliveNeighbour(List.delete(list,neighbourNode))
    else
      neighbourNode
    end
  end

  def startGossip(msg,startTime,parent,numNodes) do
    pid=String.to_atom("Child_"<>Integer.to_string(Enum.random(numNodes)))
    IO.inspect pid
    Task.start recursiveGossip(pid,msg,startTime,parent,numNodes)
  end

  def recursiveGossip(pid,msg,startTime,parent,numNodes) do
    GenServer.call(pid,{:updateStateCount,msg,startTime,parent,numNodes})
    GenServer.call(pid,{:terminate,msg,pid,parent,numNodes,startTime})
  end

  # ------------------------------- Topologies -------------------------------------- #

  def buildTopology(newTopology,numNodes) do
    case newTopology do
      "full" -> buildFullTopology(numNodes)
      #"3D" -> build3DTopology(numNodes)
      "rand2D" -> buildRand2DTopology(numNodes)
      "torus" -> buildTorusTopology(numNodes)
      "line" -> buildLineTopology(numNodes)
    #  "imp2D" -> buildimp2DTopology(numNodes)
      _ -> IO.puts "Invalid value of topology"
    end
    Enum.map(1..numNodes, fn(x) -> getNeighbours(String.to_atom("Child_"<>Integer.to_string(x))) end)
  end

  def buildTorusTopology(numNodes) do
    sqroot = round(:math.sqrt(numNodes)) #handle for non squarable
    Enum.map(1..numNodes, fn x->
      rightNode = "Child_" <> Integer.to_string(round(rem(x,sqroot) + (sqroot * Float.ceil((x/sqroot)-1)) + 1))
      topNode = "Child_"<> Integer.to_string(round(numNodes + rem(x-1,sqroot) +1 - (sqroot * (Float.ceil(x/sqroot)))))
      #IO.puts("#{inspect x}, #{inspect topNode}")
      updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), [rightNode , topNode])
    end)
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
    map =Enum.reduce(1..numNodes,map, fn x,acc->
      node = String.to_atom("Child_"<>Integer.to_string(x))
      coordinates = {(Enum.random(0..1000*10)/10000),(Enum.random(0..1000*10)/10000)}
      Map.put(acc,node,coordinates)
    end)
    IO.inspect is_map(map)
    get2DNeighbours(map)
  end

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
    end)
  end
end

