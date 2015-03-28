defmodule Mix.Tasks.Krill.ExecuteAll do
  use Mix.Task
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
  def run(args) do
    #IO.inspect(args)
    Mix.Task.run "app.start", args

    # run in parallel
    Enum.each(list_commands(), fn(command) ->
      module = Module.concat([Command, String.capitalize(command)])
      Logger.debug( module )
      apply(module, :run, [])
    end)
  end

end