defmodule Krill do
  use Behaviour
  defcallback process_std :: any
  defcallback new :: any

  def capture, do: nil
  def process_std, do: :ok



  #use Application.Behaviour
  use Application
  @moduledoc """
  """
  # def start(_type, _args) do
  #   #{:ok, _pid} = Krill.Supervisor.start_link(unquote(__MODULE__), unquote(dict))
  #   {:ok, _pid} = Krill.Supervisor.start_link
  # end

end