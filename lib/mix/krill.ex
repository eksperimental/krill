defmodule Mix.Krill do
  require File
  require Path
  require Logger

  @moduledoc false
  
  def list_commands() do
    dir = "./lib/command"
    {:ok, files} = File.ls(dir)
    Enum.map( files, &(Path.basename(&1, ".ex") |> String.to_atom) )
  end

  def local_config,
    do: Application.get_env(:krill, :config)

  def local_config(item) when is_atom(item),
    do: local_config()[item]

  def module_config(item) when is_atom(item) do
    module = Module.concat([Command, String.capitalize("#{item}")])
    apply(module, :new, [])
  end

  def module_config(items) when is_list(items),
    do: Enum.map(items, &{&1, module_config(&1)})

  def merge_config(item) when is_atom(item),
    do: Map.merge( module_config(item), local_config(item) )

end