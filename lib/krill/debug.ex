defmodule Krill.Debug do
  @moduledoc """
  Debugs the `Krill` application.
  """

  require Quaff.Debug
  require Logger

  @doc "Runs the debugger into the `module`"
  @spec run(atom) :: :ok
  def run(module) do
    Logger.debug "Debugging..."
    Quaff.Debug.start()
    Quaff.Debug.load(module)
    :ok
  end
end
