defmodule Krill.Base do

  use Behaviour
  defcallback process_std :: any
  defcallback new :: any

  def capture, do: nil
  def process_std, do: :ok
  def new, do: :ok
  
end
