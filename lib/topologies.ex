defmodule TOPOLOGIES do

    def buildTopology(newTopology,numNodes) do
      case newTopology do
        "full" -> buildFullTopology(numNodes)
        "3D" -> build3DTopology(numNodes)
        "rand2D" -> buildRand2DTopology(numNodes)
        "torus" -> buildTorusTopology(numNodes)
        "line" -> buildLineTopology(numNodes)
        "imp2D" -> buildImp2DTopology(numNodes)
        _ -> IO.puts "Invalid value of topology"
      end
      #Enum.map(1..numNodes, fn(x) -> SERVER.getNeighbours(String.to_atom("Child_"<>Integer.to_string(x))) end)
      table = :ets.new(:table, [:named_table,:public])
      :ets.insert(table,{"killedProcess",0})
      :ets.insert(table,{"ProcessList",[]})
    end
  
    # ------------------------------ Torus ------------------------------ #
  
    def buildTorusTopology(numNodes) do
      sqroot = round(:math.sqrt(numNodes)) #handle for non squarable
      Enum.map(1..numNodes, fn x->
        #rightNode = "Child_" <> Integer.to_string(round(rem(x,sqroot) + (sqroot * Float.ceil((x/sqroot)-1)) + 1))
        #topNode = "Child_"<> Integer.to_string(round(numNodes + rem(x-1,sqroot) +1 - (sqroot * (Float.ceil(x/sqroot)))))
        leftNode = if(rem(x-1,sqroot) != 0) do x-1
          else round(sqroot*Float.ceil(x/sqroot)) end
        rightNode = if(rem(x,sqroot) != 0) do x+1
          else (sqroot*round(Float.floor((x-1)/sqroot)))+1 end
        topNode = if(x <= sqroot*sqroot - sqroot) do x+sqroot
          else rem(x-1,sqroot)+1 end
        bottomNode = if(x > sqroot*sqroot - sqroot*(sqroot-1)) do x-sqroot
          else numNodes - sqroot + rem(x-1,sqroot) + 1 end
        list =  [rightNode,leftNode,bottomNode,topNode]
        |> Enum.map(fn x->
          pname= "Child_"<>Integer.to_string(x)
          pname
        end)
        SERVER.updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)),list)
      end)
    end
  
      # ------------------------------ Line ------------------------------ #
  
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
          SERVER.updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), neighbour)
      end)
    end
  
      # ------------------------------ Full ------------------------------ #
  
    def buildFullTopology(numNodes) do
      list=Enum.map(1..numNodes, fn(x)-> "Child_"<>Integer.to_string(x) end)
      Enum.each(1..numNodes, fn(x)->
        SERVER.updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), List.delete(list,"Child_"<>Integer.to_string(x))) end)
    end
  
      # --------------------------- Imperfect 2D ------------------------------ #
  
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
          SERVER.updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), neighbour)
      end)
    end
  
      # ------------------------------ 3D ------------------------------ #
  
    def build3DTopology(numNodes) do
      cubeRoot = round(:math.pow(numNodes,(1/3)))
      Enum.each(1..numNodes, fn x->
        posX = if(x+1 <= numNodes && rem(x,cubeRoot) != 0 ) do x+1 end
        posY = if(rem(x,cubeRoot*cubeRoot) != 0 && cubeRoot*cubeRoot - cubeRoot >= rem(x,(cubeRoot*cubeRoot))) do x+ cubeRoot end
        posZ = if(x+ cubeRoot*cubeRoot <= numNodes) do x+ cubeRoot*cubeRoot end
        negX = if(x-1 >= 1 && rem(x-1,cubeRoot) != 0) do x-1 end
        negY = if((cubeRoot*cubeRoot - cubeRoot*(cubeRoot-1)) < rem(x-1,(cubeRoot*cubeRoot)) + 1) do x- cubeRoot end
        negZ = if(x- cubeRoot*cubeRoot >= 1) do x- cubeRoot*cubeRoot end
        list = [posX, posY, posZ, negX,negY,negZ]
        |> Enum.reject(&is_nil/1)
        |> Enum.map(fn x->
          pname= "Child_"<>Integer.to_string(x)
          pname
        end)
        SERVER.updateNeighbours(String.to_atom("Child_"<>Integer.to_string(x)), list)
      end)
    end
  
    # --------------------------- Random 2D ----------------------------- #
  
    def buildRand2DTopology(numNodes) do
      map = Map.new()
      map =Enum.reduce(1..numNodes,map, fn x,acc->
        node = String.to_atom("Child_"<>Integer.to_string(x))
        coordinates = {(Enum.random(0..1000*10)/10000),(Enum.random(0..1000*10)/10000)}
        Map.put(acc,node,coordinates)
      end)
      #IO.inspect is_map(map)
      get2DNeighbours(map)
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
            SERVER.updateNeighbours(x, [Atom.to_string(y)])
          end
        end)
      end)
    end
  end