defmodule Krill.ProcessTest do
  use ExUnit.Case, async: true
  doctest Krill.Process
  alias Porcelain.Result
  use Krill

  setup do
    conf = %{ 
      command_name: "Testing Command",
      command: "./test/fixtures/echo.sh",
    }

    expected_out = "(line: 1) OK stdout\n(line: 3) OK stdout\n(line: 8) OK stdout\n(line: 13) OK stdout\n(line: 14) OK stdout\n(line: 15) OK stdout\n(line: 16) OK stdout\n(line: 17) OK stdout\n(line: 18) OK stdout\n(line: 20) OK stdout\n"
    expected_err = "(line: 2) ERR stderr\n(line: 4) ERR stderr\n(line: 5) ERR stderr\n(line: 6) ERR stderr\n(line: 7) ERR stderr\n(line: 9) ERR stderr\n(line: 10) ERR stderr\n(line: 11) ERR stderr\n(line: 12) ERR stderr\n(line: 19) ERR stderr\n"

    {:ok, state: new(conf), expected_out: expected_out, expected_err: expected_err, }
  end

  def exec(sender_pid, command, mode \\ :spawn_shell) do
    case mode do
      :spawn_shell ->
        opts = [ out: {:send, sender_pid}, err: {:send, sender_pid}, ]
        process = Porcelain.spawn_shell(command, opts)
        {:ok, process}

      :shell ->
        opts = [ out: :string, err: :string, ]
        process = Porcelain.shell(command, opts)
        {:ok, process}
    end
  end

  def handle_output(sender, pid, state) do
    receive do
      { ^pid, :data, :out, data } ->
        #Logger.debug "OUT: #{inspect(data)}"
        handle_output( sender, pid, Map.put(state, :stdout_raw, "#{state.stdout_raw}#{data}") )

      { ^pid, :data, :err, data } ->
        #Logger.debug "ERR: #{inspect(data)}"
        handle_output( sender, pid, Map.put(state, :stderr_raw, "#{state.stderr_raw}#{data}") )

      { ^pid, :result, result=%Result{status: status} } ->
        state = Map.merge(state, %{status_raw: status, result: result})
        #IO.puts "State (handle_output): #{inspect(state)}"
        send sender, { :ok, state }
    #after
    #  :infinity -> IO.puts "timeout"
    end
  end

  test "spawn_shell", %{state: state, expected_out: expected_out, expected_err: expected_err, } do
    #Logger.debug("PID: #{inspect self}")
    #process = Porcelain.spawn_shell(state.command, [out: {:send, self}, err: {:send, self}])
    {:ok, process} = exec(self, state.command, :spawn_shell)
    #Logger.debug("process: #{inspect process}")
    %Porcelain.Process{pid: pid} = process
    _state_handled = handle_output(self, pid, state)
    #Logger.debug("state_handled: #{inspect state_handled}")

    #Porcelain.Process.await(process, :infinity)
    receive do
      {:ok, state} ->
        state = state
    end

    #Logger.debug("state: #{inspect state}")
    #Logger.debug("result: #{inspect state.result}")

    state = Map.put(state, :process, process)
    assert state.stdout_raw == expected_out
    assert state.stderr_raw == expected_err
  end

  test "shell", %{state: state,  expected_out: expected_out, expected_err: expected_err, } do
    #Logger.debug("PID: #{inspect self}")

    #state = Krill.Process.run(state)
    {:ok, result} = exec(self, state.command, :shell)
    #Logger.debug("result: #{inspect result}")
    #Logger.debug("result: #{inspect result.err}")
    state = Map.merge( state, %{
      result: result,
      stdout_raw: result.out,
      stderr_raw: result.err,
      status_raw: result.status,
    })
    #Logger.debug inspect( Map.delete(state, :result) )
    assert state.stdout_raw == expected_out
    assert state.stderr_raw == expected_err
  end


end
