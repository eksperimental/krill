defmodule Krill.ProcessTest do
  use ExUnit.Case, async: true
  doctest Krill.Process
  alias Porcelain.Result
  use Krill

  setup do
    conf = %{ 
      command_name: "Testing Command",
      command: "./test/command/process.sh",
      #command: "htmlproof ~/git/eksperimental/krill/_site --file-ignore /docs/ --only-4xx --check-favicon --disable-external",
      #command: "htmlproof  ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --disable-external",
      #command: "htmlproof  ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
    }

    out = "this is ok (line: 1)\nthis is ok 2 (line: 3)\nthis is ok 3 (line: 6)\n"
    err = "this is is error (line: 2)\nthis is is error2 (line: 4)\nthis is is error3 (line: 5)\n"

    {:ok, state: new(conf), err: err, out: out, }
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

  test "spawn_shell", %{state: state, out: out, err: err} do
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
    assert state.stdout_raw == out
    assert state.stderr_raw == err
  end

  test "shell", %{state: state, out: out, err: err} do
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
    assert state.stdout_raw == out
    assert state.stderr_raw == err
  end


end
