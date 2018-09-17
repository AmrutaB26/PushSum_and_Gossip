defmodule PUSHSUMGOSSIP do
  use GenServer

  ## ----------- Callback functions ------------- ##

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

  def start(state) do
    {:ok, pid} = GenServer.start_link(__MODULE__,state)
    tasks = for x <- 1..10 do
      Task.async(fn -> GenServer.cast(pid, {:enqueue,x})
    end)
    end
    gossip_starter = hd(tasks)
    IO.puts("#{inspect gossip_starter.pid}")
    Enum.map(tasks, &Task.await/1)
    GenServer.call(pid, :queue)
  end
end
