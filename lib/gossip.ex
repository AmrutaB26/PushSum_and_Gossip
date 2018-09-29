defmodule GOSSIP do
  use GenServer

  ## ----------- Callback functions ------------- ##

  def start_link(num) do
    GenServer.start_link(__MODULE__,[0,[],0,1,""], name: String.to_atom("Child_"<>Integer.to_string(num)))
  end

  def init(args) do
    Process.flag(:trap_exit, true)
    {:ok, args}
  end

  def handle_cast({:neighboursList,list}, state) do
    [count,blist,s,w,message]=state
    state=[count,list++blist,s,w,message]
    {:noreply, state}
  end

  def handle_cast({:updateStateCount,msg}, state) do
    [count,blist,s,w,_]=state
    state=[count+1,blist,s,w,msg]
    IO.puts("count #{inspect state}")
    {:noreply, state}
  end

  def getState(pid) do
    GenServer.call(pid,{:getState})
  end
  def handle_call({:neighboursList}, _from, state) do
    {:reply,state, state}
  end
  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end
  ## --------------- CLient API ---------------- ##
  def updateNeighbours(id,list) do
    GenServer.cast(id,{:neighboursList, list})
  end

  def getNeighbours(id) do
    IO.inspect GenServer.call(id,{:neighboursList})
  end

  def startGossip(msg,startTime,parent,numNodes) do
    pname=String.to_atom("Child_"<>Integer.to_string(Enum.random(1..numNodes)))
    IO.puts("Starting Gossip #{inspect pname}")
    #GenServer.call(pname,{:updateStateCount,msg,startTime,parent,numNodes})
    recursiveGossip(pname,msg,startTime,parent,numNodes)    #child 6
  end

  def recursiveGossip(pid,msg,startTime,parent,numNodes) do
    IO.puts("Recursion started Gossip #{inspect pid}")
    GenServer.cast(pid,{:updateStateCount,msg})
    IO.puts("Updated state #{inspect GenServer.call(pid,{:getState})}")
    IO.puts("terminate started Gossip #{inspect pid}")
    recursion(msg,pid,parent,numNodes,startTime)
  end

  def recursion(msg,pid,parent,numNodes,startTime) do
    IO.puts ("hey #{inspect pid}")
    state = getState(pid)
    if(Enum.at(state,0)>10) do
      IO.puts "hey11"
      :ets.update_counter(:table,"killedProcess",{2,1})
      Process.exit(Process.whereis(pid),:kill)
      [{_,count}]=:ets.lookup(:table,"killedProcess")
      IO.puts " table count"
      IO.inspect count
      if(count>=numNodes) do
        IO.puts "dont come here"
        endTime=System.monotonic_time(:millisecond)
        IO.puts("Convergence reached at #{inspect (endTime-startTime) }")
        Process.exit(parent,:kill)
      end
    else
      IO.puts "hey22"
      neighpid=getRandomAliveNeighbour(Enum.at(state,1))
      IO.puts "hey33"
      if(neighpid != :false) do
        IO.puts "hey44"
        Task.async(recursiveGossip(neighpid,msg,startTime,parent,numNodes))
        recursion(msg,pid,parent,numNodes,startTime)
      end
    end
  end

  def getRandomAliveNeighbour(list) do
    if(Enum.empty?(list)) do
      IO.puts "reacheddd fallsee"
      :false
    else
      neighbourNode=Enum.random(list)
      IO.puts "amr"
      IO.inspect neighbourNode
      pid = Process.whereis(String.to_atom(neighbourNode))
      if(pid == nil) do
        getRandomAliveNeighbour(List.delete(list,neighbourNode))
      else
        String.to_atom(neighbourNode)
      end
    end
  end

  # ------------------------------- Topologies -------------------------------------- #

  def buildTopology(newTopology,numNodes) do
    case newTopology do
      "full" -> buildFullTopology(numNodes)
      #"3D" -> build3DTopology(numNodes)
      "rand2D" -> buildRand2DTopology(numNodes)
      "torus" -> buildTorusTopology(numNodes)
      "line" -> buildLineTopology(numNodes)
      "imp2D" -> buildImp2DTopology(numNodes)
      _ -> IO.puts "Invalid value of topology"
    end
    Enum.map(1..numNodes, fn(x) -> getNeighbours(String.to_atom("Child_"<>Integer.to_string(x))) end)
    table = :ets.new(:table, [:named_table,:public])
    :ets.insert(table,{"killedProcess",0})
  end

  def buildTorusTopology(numNodes) do
    sqroot = round(:math.sqrt(numNodes)) #handle for non squarable
    Enum.map(1..numNodes, fn x->
      rightNode = "Child_" <> Integer.to_string(round(rem(x,sqroot) + (sqroot * Float.ceil((x/sqroot)-1)) + 1))
      topNode = "Child_"<> Integer.to_string(round(numNodes + rem(x-1,sqroot) +1 - (sqroot * (Float.ceil(x/sqroot)))))
      IO.puts("#{inspect x}, #{inspect topNode}")
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

  def buildImp2DTopology(numNodes) do
    Enum.each(1..numNodes, fn(x) ->
      neighbour = cond do
        x==1 ->
          ["Child_"<>Integer.to_string(x+1),"Child_"<>Integer.to_string(Enum.random(1..numNodes))]
        x==numNodes ->
          ["Child_"<>Integer.to_string(x-1),"Child_"<>Integer.to_string(Enum.random(1..numNodes))]
        true->
          [("Child_"<>Integer.to_string(x-1)) , ("Child_"<>Integer.to_string(x+1)),"Child_"<>Integer.to_string(Enum.random(1..numNodes))]
        end
        updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), neighbour)
    end)
  end

  defp get2DNeighbours(list) do #TODO list of empty neighbours
    Map.keys(list)
    |> Enum.each(fn(x)->
      {refx, refy} = Map.fetch!(list,x)
      temp = Map.delete(list,x)
      keys = Map.keys(temp)
      Enum.each(keys, fn(y) ->
        {coorx,coory} = Map.fetch!(temp,y)
        if(:math.sqrt(:math.pow((refx-coorx),2) + :math.pow((refy-coory),2)) < 0.1) do
          updateNeighbours(x, [Atom.to_string(y)])
        end
      end)
    end)
  end
end

