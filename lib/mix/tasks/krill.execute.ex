defmodule Mix.Tasks.Krill.Execute do
  require Logger

  @doc false
  def run(commands) do
    commands = case commands do
      [] ->
        Application.get_env(:krill, :config) |> Keyword.keys

      [":all"] ->
        Krill.list_commands()

      _ ->
        Enum.map( commands, &(String.to_atom(&1)) )
    end

    cond do
      is_list(commands) and length(commands) > 0 -> 
        Mix.Task.run "app.start"
        #Logger.debug(inspect commands)
        Enum.map(commands, fn(command) ->
          conf = Krill.merge_config(command)
          {Task.async(conf.module, :run, [Krill.local_config(command)]), conf.timeout}
        end)
        |> Enum.each(fn({task, timeout}) ->
          Task.await(task, timeout)
        end)

      true ->
        exit({:shutdown, "No module_names provided"})
    end

    :ok
  end
  
end