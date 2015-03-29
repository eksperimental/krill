defmodule Krill.CommandTest do
  use ExUnit.Case, async: true
  import Krill
  require Command.Sample
  require Logger
  import ExUnit.CaptureIO  

  setup do
    conf  = Mix.Krill.local_config(:sample)

    {:ok, conf: conf, }
  end

  test "sample", %{conf: conf, } do
    {:ok, state} = Command.Sample.run(conf)
    #{:ok, state} = Mix.Tasks.Krill.Execute.run(["sample"])
    merge_output = fn -> merge_output(state.stdout, state.stderr) end

    expected_out = "(line: 1) OK stdout\n(line: 3) OK stdout\n(line: 8) OK stdout\n(line: 13) OK stdout\n(line: 14) OK stdout\n(line: 15) OK stdout\n(line: 16) OK stdout\n(line: 17) OK stdout\n(line: 20) OK stdout\n"
    expected_err = "(line: 2) ERR stderr\n(line: 4) ERR stderr\n(line: 5) ERR stderr\n(line: 6) ERR stderr\n(line: 7) ERR stderr\n(line: 9) ERR stderr\n(line: 10) ERR stderr\n(line: 11) ERR stderr\n(line: 19) ERR stderr\n"
    
    assert capture_io(fn ->
      print_output( merge_output.() )
    end) == expected_out

    assert capture_io(:stderr, fn ->
      print_output( merge_output.() )
    end) == expected_err

    assert capture_io(fn ->
      Command.Sample.run(conf)
    end) == "Running: #{state.title}\n$ #{state.command}\n\n" <> expected_out

    assert capture_io(:stderr, fn ->
      Command.Sample.run(conf)
    end) == expected_err <> "ERROR: #{state.command_name} - Errors have been found.\n"
 
  end

end
