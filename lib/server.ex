defmodule SERVER do
  use GenServer

  ## ----------- Callback functions ------------- ##

  def start_link(num) do
    GenServer.start_link(__MODULE__,[0,[],num,1,""], name: String.to_atom("Child_"<>Integer.to_string(num)))
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
    {:noreply, state}
  end

  def handle_cast({:updatePushSum,newS,newW,count},state) do
    [_,blist,_,_,msg]=state
    state=[count,blist,newS,newW,msg]
    {:noreply, state}
  end

  def handle_cast({:neigh,msg,startTime,numNodes},state) do
    neighNode=getRandomAliveNeighbour((Enum.at(state,1)))
    if(neighNode != :false) do
      spawn fn -> GenServer.cast(neighNode,{:accept,msg,startTime,numNodes}) end
      GenServer.cast(self(),{:neigh,msg,startTime,numNodes})
    end
      {:noreply,state}
  end

  def handle_cast({:accept,msg,numNodes,startTime},state) do
    if(Enum.at(state,0)>=10) do
      stopExecution(numNodes,startTime,self())
    else
     if(Enum.at(state,0)==0) do
        GenServer.cast(self(),{:neigh,msg,startTime,numNodes})
     end
    end
    [count,list,s,w,_]=state
    {:noreply,[count+1,list,s,w,msg],state}
  end

  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end

  def handle_call({:converge,startTime},_from,_) do
    endTime = System.os_time(:millisecond)
    time = endTime-startTime
    IO.puts("Convergence reached at #{inspect time}ms")
    System.halt(1)
  end

  def handle_call({:terminate,startTime,tcount,numNodes,prevstate},_from,_) do
    endTime = System.monotonic_time(:millisecond)
    time = endTime-startTime
    IO.puts("Convergence reached at #{inspect time}ms")
    :ets.insert(:table,{"killedProcess",0})
    :ets.insert(:table,{"ProcessList",[]})
    #Enum.map(1..numNodes, fn(x) ->
     # pname = (String.to_atom("Child_"<>Integer.to_string(x)))
     # state = getState(pname)
     # IO.puts("#{inspect Enum.at(state,0)} #{inspect (Enum.at(state,2)/Enum.at(state,3))}") # pname
    #end)
      IO.puts("Nodes converged: #{inspect tcount}")
      IO.puts("Total nodes: #{inspect numNodes}")
      IO.puts("Convergence ratio S/W: #{inspect (Enum.at(prevstate,2)/Enum.at(prevstate,3))}")
    System.halt(1)
  end

  def updateNeighbours(id,list) do
    GenServer.cast(id,{:neighboursList, list})
  end

  def getState(pid) do
    GenServer.call(pid,{:getState})
  end

  ## ----------------------- CLient API --------------------- ##

  def stopExecution(numNodes,startTime,state,pid) do
    [{_,list}]=:ets.lookup(:table,"ProcessList")
    if(Enum.any?(list,fn x-> x==pid end) == :false) do
      :ets.insert(:table,{"ProcessList",[pid]++list})
      :ets.update_counter(:table,"killedProcess",{2,1})
    end
    [{_,tcount}]=:ets.lookup(:table,"killedProcess")
    [{_,table1}]=:ets.lookup(:table,"Algorithm")
    percent = if(table1 == "push-sum") do
      [{_,name}]=:ets.lookup(:table,"Topology")
      case name do
        "imp2D" -> 0.55
        "line" -> 0.9
        "rand2D" -> 0.75
        _ -> 0.85
      end
    else
      0.9
    end
    #IO.puts percent
    if(tcount >= trunc(numNodes*percent)) do   #ratio less for imp2D from 50-70 and line of about 90-100
      GenServer.call(:Child_0,{:terminate,startTime,tcount,numNodes,state})
    end
  end

  ## ------------------------ GOSSIP ------------------- ##

  def startGossip(msg,startTime,numNodes) do
    pname=String.to_atom("Child_"<>Integer.to_string(:rand.uniform(numNodes)))
    GenServer.cast(pname,{:accept,msg,numNodes,startTime})
    infiniteloop(startTime)
  end

  def infiniteloop(startTime) do
    endTime = System.os_time(:millisecond)
    time = endTime - startTime
    if(time<=50000) do infiniteloop(startTime)
    else
      IO.puts "Convergence could not be reached within 50000ms"
      System.halt(1)
    end
  end

  def stopExecution(numNodes,startTime,pid) do
    [{_,list}]=:ets.lookup(:table,"ProcessList")
    if(Enum.any?(list,fn x-> x==pid end) == :false) do
      :ets.insert(:table,{"ProcessList",[pid]++list})
      :ets.update_counter(:table,"killedProcess",{2,1})
    end
    [{_,tcount}]=:ets.lookup(:table,"killedProcess")
      if(tcount >= trunc(numNodes*0.9)) do
        GenServer.call(:Child_0,{:converge,startTime})
      end
  end

  def getRandomAliveNeighbour(list) do
    if(Enum.empty?(list)) do
      :false
    else
      neighbourNode=Enum.random(list)
      pid = String.to_atom(neighbourNode)
      [{_,nlist}]=:ets.lookup(:table,"ProcessList")
      if(Enum.any?(nlist,fn x-> x==pid end) != :false) do
        getRandomAliveNeighbour(List.delete(list,neighbourNode))
      else String.to_atom(neighbourNode) end
    end
  end

  ## ------------------------------- PUSH SUM -------------------------------------- ##

  def startPushSum(numNodes,startTime) do
    IO.puts "Push-sum started for #{numNodes} nodes"
    Enum.map(1..numNodes, fn(x)->
      pname = String.to_atom("Child_"<>Integer.to_string(x))
      propogatePushSum(pname,0,0,numNodes,startTime)
    end)
  end

  def propogatePushSum(pname,s,w,numNodes,startTime) do
    state = getState(pname)
    oldS=Enum.at(state,2)
    oldW=Enum.at(state,3)
    count=Enum.at(state,0)
    newS = (s+oldS)
    newW = (w+oldW)
    diff = abs((newS/newW) - (oldS/oldW))
    neighNode = getNeighboursPushSum(Enum.at(state,1))

    if(count != -1) do
      ncount = calculateCounter(diff,numNodes,count,startTime,state,pname)
      GenServer.cast(pname,{:updatePushSum,newS/2,newW/2,ncount})
    end
      if(neighNode != :false) do
        val1 = if(count != -1) do newS/2 else oldS/2 end
        val2 = if(count != -1) do newW/2 else oldW/2 end
        #IO.puts("From #{inspect pname} to #{inspect neighNode}")
        spawn fn -> propogatePushSum(neighNode,val1,val2, numNodes, startTime) end
        Process.sleep(100)
      else
        stopExecution(numNodes,startTime,state,pname)
      end
  end

  def calculateCounter(diff,numNodes,count,startTime,state,pname) do
    if(diff < :math.pow(10,-10) && (count==2)) do
      #:ets.update_counter(:table,"killedProcess",{2,1})
      stopExecution(numNodes,startTime,state,pname)
      -1
    else
      if(diff >= :math.pow(10,-10)) do 0 else count+1 end
    end
  end

  def getNeighboursPushSum(list) do
    if(Enum.empty?(list)) do
      :false
    else
      neigh = String.to_atom(Enum.random(list))
      st = getState(neigh)
      if(Enum.at(st,0)==-1) do
        getNeighboursPushSum(List.delete(list,Atom.to_string(neigh)))
      else
        neigh
      end
    end
  end
end
