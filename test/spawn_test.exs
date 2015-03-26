defmodule Krill.SpawnTest do
  use ExUnit.Case, async: true
  require Logger

  def capitalize(name) do
    #{ pid, String.capitalize(string) }
    receive do
      {sender, {field, msg} } ->
        #Logger.debug "Name: #{name}"
        result = Map.put( %{}, field, String.capitalize(msg) )
        #Logger.debug "result: #{inspect(result)}"
        send sender, { :ok, result }
        capitalize(name)
    end
  end

  def handle_output(state) do
    receive do
      {:ok, message} ->
        #Logger.debug "handle_output message: #{inspect(message)}"
        new_state = message
    end
    Map.merge(state, new_state)
  end

  test "spawn" do
    state = %{foo: "bar"}
    pid = spawn(__MODULE__, :capitalize, [:foo])
    #Logger.debug inspect(pid)

    send pid, { self, {:hello, "world"} }  
    state = handle_output(state)
    #Logger.debug "state #1: #{inspect(state)}"

    send pid, {self, {:hola, "mundo"} }
    state = handle_output(state)

    #Logger.debug "state: #{inspect(state)}"
    
    assert state == %{foo: "bar", hola: "Mundo", hello: "World", }
  end

end
