defmodule Todo.List do
	defstruct auto_id: 1, entries: HashDict.new

  # Constructor new/0
	def new, do: %Todo.List{}

	# Constructor new/1
	# Example usage: TodoList.new([%{date: {2013, 12, 19}, title: "Dentist"},
	#                              %{date: {2013, 12, 20}, title: "Movies"}])
	def new(entries) do
	  Enum.reduce(
		  entries,
			%Todo.List{},
			fn(entry, todo_list_acc) ->
				add_entry(todo_list_acc, entry)
			end
		)
	end

  #Example usage:
  # TodoList.add_entry(todo_list, %{date: {2013, 12, 19}, title: "Concert"})
	def add_entry(%Todo.List{entries: entries, auto_id: auto_id} = todo_list, entry) do
		entry = Map.put(entry, :id, auto_id) # set the new entry's ID
		new_entries = HashDict.put(entries, auto_id, entry) # add the new entry to the entries list

    # update the struct, incrementing the ID by 1
		%Todo.List{todo_list | entries: new_entries, auto_id: auto_id + 1 }
	end

  # Example usage:
  # TodoList.entries(todo_list, {2013, 12, 19})
	def entries(%Todo.List{entries: entries}, date) do
		entries
		|> Stream.filter(fn({_, entry}) -> # filter entries for a given date
			   entry.date == date
		   end)
		|> Enum.map(fn({_, entry}) -> # extract only the entry from the resulting {id, entry} tuple
			   entry
		   end)
	end

  # Example usage:
  # TodoList.update_entry(todo_list, 1, fn(x) -> Map.put(x, :date, {2013, 12, 20}))
	def update_entry(%Todo.List{entries: entries} = todo_list, entry_id, updater_fun) do
		case entries[entry_id] do
			nil -> todo_list # if no entry, return the original todo_list

			old_entry -> # if entry exists, perform the update and return the modified list
				old_entry_id = old_entry.id
				new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry) # make sure new_entry is a Map and that the ID didn't change
				new_entries = HashDict.put(entries, new_entry.id, new_entry)
				%Todo.List{todo_list | entries: new_entries}
		end
	end

  # Example usage:
	# TodoList.delete_entry(todo_list, 2)
	def delete_entry(%Todo.List{entries: entries} = todo_list, entry_id) do
		case entries[entry_id] do
			nil -> todo_list

			existing_entry ->
				new_entries = HashDict.delete(entries, entry_id)
				%Todo.List{entries: new_entries}
		end
	end
end

defmodule Todo.List.CsvImporter do

	def import(file_name) do
    file_name
		|> read_lines
		|> create_entries
		|> Todo.List.new
	end

	defp read_lines(file) do
		file
		|> File.stream!
		|> Enum.map(&String.replace(&1, "\n", ""))
	end

  # Input example: ["2013/12/19,Dentist", "2013/12/20,Shopping", "2013/12/19,Movies"]
	defp create_entries(lines) do
		lines
		|> Enum.map(&extract_fields/1)
		|> Enum.map(&create_entry/1)
	end

  # Input example: "2013/12/19,Dentist"
	defp extract_fields(line) do
		line
		|> String.split(",")
		|> convert_date
	end

  # Input example: ["2013/12/19", "Dentist"]
	defp convert_date([date_string, title]) do
		{parse_date(date_string), title}
	end

	# Input example: "2013/12/19"
	defp parse_date(date_string) do
    date_string
		|> String.split("/")
		|> Enum.map(&String.to_integer/1)
		|> List.to_tuple
	end

  # Input example: {{2013,12,19}, "Dentist"}
	defp create_entry({date, title}) do
    %{date: date, title: title}
  end
end

defimpl Collectable, for: Todo.List do
	# Example usage:
	#   for entry <- entries, into: TodoList.new, do: entry
	def into(original) do
		{original, &into_callback/2}
	end

  # Appender implementation
	defp into_callback(todo_list, {:cont, entry}) do
		Todo.List.add_entry(todo_list, entry)
	end

	defp into_callback(todo_list, :done), do: todo_list
	defp into_callback(todo_list, :halt), do: :ok
end
