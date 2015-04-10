defmodule Mix.Tasks.Krill.Execute do
  @shortdoc "Executes commands"
  @moduledoc """
  Executes the commands provided in list `commands`.

  Usage: `mix krill.execute commands`

  ## Examples
  `mix krill.execute`
  
  If no commands are provided, then modules in the `config/config.exs` file are loaded.

  `mix krill.execute sample`
  `mix krill.execute sample htmlproof`
  
  One or more commands If `mix krill.execute command_one command_two`.
  
  `mix krill.execute :all`
  
  If `mix krill.execute :all` is called, then `.ex` files under `lib/command/`
  are used as commands (based on their file names).
  """

  use Mix.Task
  require Logger


  @doc """
  Executes the commands provided in list `commands`.

  If list is empty, then modules in the `config/config.exs` file are loaded.
  One or more commands If `mix krill.execute command_one command_two`.
  
  If `mix krill.execute :all` is called, then `.ex` files under `lib/command/`
  are used as commands (based on their file names).

  `commands` should be a list containing only strings.
  Returns :ok
  """
  @spec run([String.t]) :: :ok
  def run(commands) when is_list(commands) do
    commands = case commands do
      [] ->
        Application.get_env(:krill, :config) |> Keyword.keys

      [":all"] ->
        Krill.list_commands()

      _ ->
        Enum.map( commands, &(String.to_atom(&1)) )
    end

    cond do
      length(commands) > 0 -> 
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