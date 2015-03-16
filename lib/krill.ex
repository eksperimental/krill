defmodule Krill do
  use Application.Behaviour
  #use Application
  @moduledoc """
  """
  def start(_type, _args) do
    #{:ok, _pid} = Krill.Supervisor.start_link(unquote(__MODULE__), unquote(dict))
    {:ok, _pid} = Krill.Supervisor.start_link
  end
end