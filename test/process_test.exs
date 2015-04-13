defmodule Krill.ProcessTest do
  use ExUnit.Case, async: true
  doctest Krill.Process
  alias Krill.Parser
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

  test "spawn_shell", %{state: state, expected_out: expected_out, expected_err: expected_err, } do
    {:ok, process} = exec(self, state.command, :spawn_shell)
    %Porcelain.Process{pid: pid} = process
    _state_handled = Krill.Process.handle_output(self, pid, state)

    receive do
      {:ok, state} ->
        state = state
    end
    IO.inspect(state)

    state = Map.put(state, :process, process)
    assert (Parser.denumerify(state.stdout_raw) |> Parser.join) <> "\n" == expected_out
    assert (Parser.denumerify(state.stderr_raw) |> Parser.join) <> "\n" == expected_err
  end

  test "shell", %{state: state,  expected_out: expected_out, expected_err: expected_err, } do
    {:ok, result} = exec(self, state.command, :shell)
    state = Map.merge( state, %{
      result: result,
      stdout_raw: result.out,
      stderr_raw: result.err,
      status_raw: result.status,
    })
    assert state.stdout_raw == expected_out
    assert state.stderr_raw == expected_err
  end

  # test "determine_status" is done in `krill_test.exs`
end
