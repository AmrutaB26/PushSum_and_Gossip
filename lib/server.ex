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
    #IO.puts("updated state #{inspect state}")
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
    initiateGossip(pname,msg,startTime,parent,numNodes)    #child 6
  end

  def initiateGossip(pid,msg,startTime,parent,numNodes) do
    #IO.puts("State updated of #{inspect pid}")
    GenServer.cast(pid,{:updateStateCount,msg})
    spawnNeighbours(msg,pid,parent,numNodes,startTime)
  end
  def stopExecution(numNodes,startTime,state,pid) do
    [{_,list}]=:ets.lookup(:table,"ProcessList")
    if(Enum.any?(list,fn x-> x==pid end) != :false) do
      :ets.update_counter(:table,"killedProcess",{2,1})
    else
      :ets.insert(:table,{"ProcessList",[pid]++list})
    end
    [{_,tcount}]=:ets.lookup(:table,"killedProcess")
      if(tcount >= trunc(numNodes*0.9)) do
        #IO.puts(" killing process counter#{inspect tcount} #{inspect state}  #{inspect numNodes} ")
        endTime = System.monotonic_time(:millisecond)
        time = endTime-startTime
        Enum.map(1..numNodes, fn(x) -> 
          pname = (String.to_atom("Child_"<>Integer.to_string(x)))
          state = getState(pname)
          IO.puts("#{inspect Enum.at(state,0)} #{inspect (Enum.at(state,2)/Enum.at(state,3))}") # 
        end)
        IO.puts("Convergence reached at #{inspect time} #{inspect tcount}")
        System.halt(1)
      end
  end

  def spawnNeighbours(msg,pid,parent,numNodes,startTime) do
    state=getState(pid)
    if(Enum.at(state,0)>=10) do
      stopExecution(numNodes,startTime,state,pid)
    else
      neighNode=getRandomAliveNeighbour((Enum.at(state,1)))
      if(neighNode != :false) do
        #IO.puts("From #{inspect pid} to #{inspect neighNode}")
        ppid= spawn fn -> initiateGossip(neighNode,msg,startTime,parent,numNodes) end
        #IO.inspect ppid
        spawnNeighbours(msg,pid,parent,numNodes,startTime)
      else
        stopExecution(numNodes,startTime,state,pid)
      end
    end
  end

  def getRandomAliveNeighbour(list) do
    if(Enum.empty?(list)) do
      #IO.puts "reacheddd fallsee"
      :false
    else
      neighbourNode=Enum.random(list)
      #IO.puts "amr"
      #IO.inspect neighbourNode
      pid = String.to_atom(neighbourNode)
      if(Enum.at(getState(pid),0)>=10) do
        getRandomAliveNeighbour(List.delete(list,neighbourNode))
      else
        String.to_atom(neighbourNode)
      end
    end
  end

  # ------------------------------- Topologies -------------------------------------- #

  
  def startPushSum(numNodes,startTime) do
    Enum.map(1..numNodes, fn(x)-> 
      pname = String.to_atom("Child_"<>Integer.to_string(x))
      propogatePushSum(pname,0,0,numNodes,startTime)
      #Process.sleep(100)
    end)
  end

  def propogatePushSum(pname,s,w,numNodes,startTime) do
    state = getState(pname)
    oldS=Enum.at(state,2)
    oldW=Enum.at(state,3)
    count=Enum.at(state,0)
    newS = (s+oldS)/2
    newW = (w+oldW)/2
    
    diff=(newS/newW) - (oldS/oldW)
    ncount = calculateCounter(diff,numNodes,count,startTime,state,pname)
      
      GenServer.cast(pname,{:updatePushSum,newS,newW,ncount})
      neighNode = getRandomAliveNeighbour(Enum.at(state,1))
      if(neighNode != :false) do
        #IO.puts("From #{inspect pname} to #{inspect neighNode}")
        spawn fn -> propogatePushSum(neighNode,newS, newW, numNodes, startTime) end
        Process.sleep(100)
        #propogatePushSum(pname,newS,newW,numNodes,startTime)
      else
        #IO.puts("killing process #{inspect pname} #{inspect state}")
        stopExecution(numNodes,startTime,state,pname)
      end
      
  end
  
  def calculateCounter(diff,numNodes,count,startTime,state,pname) do
    if(diff < :math.pow(10,-10) && (count==2)) do
      #:ets.update_counter(:table,"killedProcess",{2,1})
      stopExecution(numNodes,startTime,state,pname)
      ncount = 10
    else 
      if(diff >= :math.pow(10,-10)) do
        ncount=0
      else
        ncount = count+1
      end
    end
  end

  

  def handle_cast({:updatePushSum,newS,newW,count},state) do
    [_,blist,_,_,msg]=state
    state=[count,blist,newS,newW,msg]
    [{_,tcount}]=:ets.lookup(:table,"killedProcess")
    #IO.puts("updated state #{inspect Enum.at(state,2)} #{inspect Enum.at(state,3)} #{inspect tcount}}")
    {:noreply, state}
  end
end

