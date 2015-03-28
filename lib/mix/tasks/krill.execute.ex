defmodule Mix.Tasks.Krill.Execute do
  #use Mix.Task
  import Mix.Krill
  require Logger

  #@shortdoc "Create the storage for the repo"

  @moduledoc """
  Create the storage for the repository.

  ## Examples

      mix krill.execute
      mix krill.execute -r Custom.Repo

  ## Command line options

    * `-r`, `--repo` - the repo to create (defaults to `YourApp.Repo`)
    * `--no-start` - do not start applications

  """

  @doc false
  def run(module_names) do
    case module_names do
      [] ->
        module_names = Application.get_env(:krill, :commands)

      [":all"] ->
        module_names = list_commands()

      _ ->
        nil
    end

    cond do
      is_list(module_names) and length(module_names) > 0 -> 
        Mix.Task.run "app.start"
        modules = Enum.map(module_names, &(Module.concat([Command, String.capitalize(&1)])))
        
        #start_jobs(modules, :run)
        #collect_responses(length(modules))

        Enum.map(modules, fn(module) ->
          Task.async(module, :run, [])
        end)
        |> Enum.each(fn(task) ->
          Task.await(task, :infinity)
        end)

      true ->
        exit({:shotdown, "No module_names provided"})
    end
  end

  defp start_jobs(modules, fun) do
    caller = self
    Enum.each(modules, fn(module) ->
      spawn(fn() ->
        execute_job(caller, module, fun)
      end)
    end)
  end

  defp execute_job(caller, module, fun) do
    response = apply(module, fun, [])
    #caller <- {:response, response}
    send( caller, {:response, response})
  end

  defp collect_responses(expected) do
    Enum.map(1..expected, fn(_) ->
      get_response
    end)
  end

  defp get_response do
    receive do
      {:response, response} -> response
    end
  end

end