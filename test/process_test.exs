defmodule Krill.ProcessTest do
  use ExUnit.Case, async: true
  doctest Krill.Process
  alias Porcelain.Result
  use Krill

  setup do
    conf = %{ 
      command_name: "Testing Command",
      command: "./test/command/process.sh",
    }

    {:ok, state: new(conf), }
  end

  def exec(pid, command, mode \\ :spawn_shell) do
    case mode do
      :spawn_shell ->
        opts = [ out: {:send, pid}, err: {:send, pid}, ]
        process = Porcelain.spawn_shell(command, opts)
        {:ok, process}

      :shell ->
        opts = [ out: :string, err: :string, ]
        process = Porcelain.shell(command, opts)
        {:ok, process}
    end
  end

  def receive_result(state) do
    receive do
      {:ok, message} ->
        #Logger.debug "handle_output message: #{inspect(message)}"
        new_state = message
      {:result, message} ->
        new_state = message
    end
    Map.merge(state, new_state)
  end

  def handle_properly(sender, pid_shell, state) do
    receive do
      { ^pid_shell, :data, :out, data } ->
        Logger.debug "OUT: #{inspect(data)}"
        handle_properly( sender, pid_shell, Map.put(state, :stdout_raw, "#{state.stdout_raw}#{data}") )

      { ^pid_shell, :data, :err, data } ->
        Logger.debug "ERR: #{inspect(data)}"
        handle_properly( sender, pid_shell, Map.put(state, :stderr_raw, "#{state.stderr_raw}#{data}") )

      { ^pid_shell, :result, result=%Result{status: status} } ->
        state = Map.merge(state, %{status_raw: status, result: result})
        IO.puts "State (handle_properly): #{inspect(state)}"
        send sender, { :ok, state }
    #after
    #  :infinity -> IO.puts "timeout"
    end
  end

  test "spawn_shell", %{state: state} do
    Logger.debug("PID: #{inspect self}")
    #process = Porcelain.spawn_shell(state.command, [out: {:send, self}, err: {:send, self}])
    {:ok, process} = exec(self, state.command, :spawn_shell)
    Logger.debug("process: #{inspect process}")
    %Porcelain.Process{pid: pid_shell} = process
    state_handled = handle_properly(self, pid_shell, state)
    Logger.debug("state_handled: #{inspect state_handled}")

    #Porcelain.Process.await(process, :infinity)
    receive do
      {:ok, state} ->
        state = state
    end

    Logger.debug("state: #{inspect state}")
    Logger.debug("result: #{inspect state.result}")

    state = Map.put(state, :process, process)
    assert state.stdout_raw == "this is ok (line: 1)\nthis is ok 2 (line: 3)\nthis is ok 3 (line: 6)\n"
    assert state.stderr_raw == "this is is error (line: 2)\nthis is is error2 (line: 4)\nthis is is error3 (line: 5)\n"
  end

  test "shell", %{state: state} do
    Logger.debug("PID: #{inspect self}")

    #state = Krill.Process.run(state)
    {:ok, result} = exec(self, state.command, :shell)
    Logger.debug("result: #{inspect result}")
    state = Map.put(state, :result, result)
    state = Map.put(state, :stdout_raw, result.out)
    state = Map.put(state, :stderr_raw, result.err)
    state = Map.put(state, :status_raw, result.status)
    Logger.debug inspect( Map.delete(state, :result) )
    assert state.stdout_raw == "this is ok (line: 1)\nthis is ok 2 (line: 3)\nthis is ok 3 (line: 6)\n"
    assert state.stderr_raw == "this is is error (line: 2)\nthis is is error2 (line: 4)\nthis is is error3 (line: 5)\n"
  end


end
