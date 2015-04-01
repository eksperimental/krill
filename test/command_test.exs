defmodule Krill.CommandTest do
  use ExUnit.Case, async: true
  require Logger
  import Krill
  import ExUnit.CaptureIO
  alias Command.Sample

  defmodule Basic, do: use Krill
  
  setup do
    sample = %{
      conf: local_config(:sample),
      expected_out: "(line: 1) OK stdout\n(line: 3) OK stdout\n(line: 8) OK stdout\n(line: 13) OK stdout\n(line: 14) OK stdout\n(line: 15) OK stdout\n(line: 16) OK stdout\n(line: 17) OK stdout\n(line: 20) OK stdout\n",
      expected_err: "(line: 2) ERR stderr\n(line: 4) ERR stderr\n(line: 5) ERR stderr\n(line: 6) ERR stderr\n(line: 7) ERR stderr\n(line: 9) ERR stderr\n(line: 10) ERR stderr\n(line: 11) ERR stderr\n(line: 19) ERR stderr\n",
    }
    {:ok, sample: sample, }
  end

  test "new(nil)" do
    state = Basic.new(%{title: "Test", command: "./test foo bar"})
    for n <- [ state.command_name, state.input, ],
      do: assert n == nil

    for n <- [ state.module, state.accept, state.reject, state.message_ok, state.message_error,],
      do: refute n == nil

    assert state.title == "Test"
    assert state.command == "./test foo bar"
    assert state.stdout == []
  end

  test "new with config" do
    state = Basic.new(%{title: "Test", command: "./test foo bar"})

    for n <- [ state.command_name, state.input, ],
      do: assert n == nil

    for n <- [state.accept, state.reject, state.message_ok, state.message_error, ],
      do: refute n == nil

    assert state.title == "Test"
    assert state.command == "./test foo bar"
    assert state.stdout == []
  end

  test "Sample.run", %{sample: sample, } do
    {:ok, state} = Sample.run(sample.conf)
    merge_output = fn -> merge_output(state.stdout, state.stderr) end

    assert capture_io(fn ->
      print_output( merge_output.() )
    end) == sample.expected_out

    assert capture_io(:stderr, fn ->
      print_output( merge_output.() )
    end) == sample.expected_err

    assert capture_io(fn ->
      Sample.run(sample.conf)
    end) == "Running: #{state.title}\n$ #{state.command}\n\n" <> sample.expected_out

    assert capture_io(:stderr, fn ->
      Sample.run(sample.conf)
    end) == sample.expected_err <> "ERROR: #{state.command_name} - Errors have been found.\n" 
  end
  
end
