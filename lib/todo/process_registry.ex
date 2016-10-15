# A HashDict abstraction that keeps track of processes and their pids for
# easy discovery by other modules.
# Format is: {:registered_alias, registered_pid}
defmodule Todo.ProcessRegistry do
  use GenServer
  import Kernel, except: [send: 2]

  def start_link do
    IO.puts "Starting process registry."
    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def whereis_name(key) do
    GenServer.call(:process_registry, {:whereis_name, key})
  end

  def unregister_name(key) do
    GenServer.call(:process_registry, {:unregister_name, key})
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined -> {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def init(_) do
    {:ok, HashDict.new}
  end

  def handle_call({:register_name, key, pid}, _, process_registry) do
    case HashDict.get(process_registry, key) do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, HashDict.put(process_registry, key, pid)}
      _ ->
        {:reply, :no, process_registry}
    end
  end

  def handle_call({:unregister_name, key}, _, process_registry) do
    {:reply, key, HashDict.delete(process_registry, key)}
  end

  def handle_call({:whereis_name, key}, _, process_registry) do
    {
      :reply,
      HashDict.get(process_registry, key, :undefined),
      process_registry
    }
  end

  def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  def handle_info(_, state), do: {:noreply, state}

  # Iterate through the key-value pairs and delete the items where the key
  # matches the provided pid.
  defp deregister_pid(process_registry, pid) do
    Enum.reduce(
      process_registry,
      process_registry,
      fn
        ({registered_alias, registered_process}, registry_acc) when registered_process == pid ->
          HashDict.delete(registry_acc, registered_alias)

        (_, registry_acc) -> registry_acc
      end
    )
  end
end
