defmodule Mix.Krill do
  require File
  require Path
  require Logger
  # Conveniences for writing Mix.Tasks in Krill.
  @moduledoc false

  def list_commands() do
    dir = "./lib/command"
    # list all .ex files under `dir`
    {:ok, files} = File.ls(dir)
    Logger.debug(inspect files)
    
    Enum.map( files, &(Path.basename(&1, ".ex")) )
  end
end