defmodule Krill.Debug do
  require Logger

  def run() do
    Logger.debug "Debugging.."
    Quaff.Debug.start()
    Quaff.Debug.load(Krill.Sample)
  end
end
