defmodule Krill.Debug do
  require Logger

  def run(module) do
    Logger.debug "Debugging..."
    Quaff.Debug.start()
    Quaff.Debug.load(module)
  end
end
