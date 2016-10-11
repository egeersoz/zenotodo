defmodule Todo.Server do
  use GenServer

  def start(name) do
    GenServer.start(Todo.Server, name)
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

	# Callbacks

  def init(name) do
    {:ok, {name, Todo.Database.get(name) || Todo.List.new}}
  end

  # handle_cast(request, state)
	def handle_cast(request, {name, todo_list}) do
    case request do
      {:add_entry, new_entry} ->
        new_state = Todo.List.add_entry(todo_list, new_entry)
        Todo.Database.store(name, new_state)
        {:noreply, {name, new_state}}
      {:delete_entry, entry_id} ->
        new_state = Todo.List.delete_entry(todo_list, entry_id)
        Todo.Database.store(name, new_state)
        {:noreply, new_state}
      {:update_entry, entry_id, updater_fun} ->
        new_state = Todo.List.update_entry(todo_list, entry_id, updater_fun)
        Todo.Database.store(name, new_state)
        {:noreply, new_state}
      invalid_request ->
        {:noreply, todo_list}
    end
  end

  # handle_call(request, from, state)
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}}
  end
end
