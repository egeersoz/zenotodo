defmodule Todo.Server do
  use GenServer

	def start do
		GenServer.start(Todo.Server, nil)
	end

  def init(_) do
    {:ok, Todo.List.new}
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

	# Client TodoList functions
	def add_entry(todo_server, new_entry) do
		GenServer.cast(todo_server, {:add_entry, new_entry})
	end

	def update_entry(todo_server, {:update_entry, entry_id, updater_fun}) do
		GenServer.cast(todo_server, {:update_entry, entry_id, updater_fun})
	end

	def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
	end

	def delete_entry(todo_server, entry_id) do
		GenServer.cast(todo_server, {:delete_entry, entry_id})
	end

	# Server TodoList functions
	def handle_cast(request, todo_list) do
    case request do
      {:add_entry, new_entry} ->
        {:noreply, Todo.List.add_entry(todo_list, new_entry)}
      {:delete_entry, entry_id} ->
        {:noreply, Todo.List.delete_entry(todo_list, entry_id)}
      {:update_entry, entry_id, updater_fun} ->
        {:noreply, Todo.List.update_entry(todo_list, entry_id, updater_fun)}
      invalid_request ->
        {:noreply, todo_list}
    end
  end

  def handle_call({:entries, date}, _, todo_list) do
    {:reply, Todo.List.entries(todo_list, date), todo_list}
  end
end
