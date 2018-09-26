defmodule GOSSIP do
  use GenServer

  ## ----------- Callback functions ------------- ##

  def start_link(args) do
    {:ok, pid} = GenServer.start_link(__MODULE__,args)
    IO.puts "here"
  end
  def init(args) do
    IO.puts :ok
    {:ok, args}
  end
  def handle_call(:queue, _from, state) do
    {:reply,state,state}
  end
  #def handle_call({:enqueue,value}, state) do
  #  newval = [value | state]
   # {:reply, newval, state}
  #end
  def handle_cast({:enqueue,value}, state) do
    newval = [value | state]
    {:noreply, newval}
  end

  def handle_call(:dequeue, _from, [value | state]) do
    {:reply, value, state}
  end
  def handle_call(:dequeue, _from, []) do
    {:reply, nil, []}
  end

  ## --------------- CLient API ---------------- ##

 # def create(board_id) do
  #  case GenServer.whereis(ref(board_id)) do
   #   nil ->
    #    Supervisor.start_child(PhoenixTrello.BoardChannel.Supervisor, [board_id])
     # _board ->
      #  {:error, :board_already_exists}
   # end
 # end

 # defp ref(board_id) do
  #  {:global, {:board, board_id}}
 # end
  #def start() do
   # tasks = for x <- 1..10 do
    # Task.async(fn -> GenServer.cast(pid, {:enqueue,x})
    #end)
    #end
    #IO.inspect tasks
    #gossip_starter = hd(tasks)
    #IO.inspect Process.alive?(gossip_starter.pid)
    #IO.puts("#{inspect gossip_starter.pid}")
    #Enum.map(tasks, &Task.await/1)
    #GenServer.call(pid, :queue)
  #end
end
