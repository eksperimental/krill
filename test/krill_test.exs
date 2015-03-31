defmodule KrillTest do
  use ExUnit.Case, async: true
  doctest Krill

  require Logger
  import Krill
  import ExUnit.CaptureIO
  alias Command.Sample

  defmodule Command.Basic, do: use Krill
  alias Command.Basic

  setup do
    sample = %{
      conf: local_config(:sample),
      expected_out: "(line: 1) OK stdout\n(line: 3) OK stdout\n(line: 8) OK stdout\n(line: 13) OK stdout\n(line: 14) OK stdout\n(line: 15) OK stdout\n(line: 16) OK stdout\n(line: 17) OK stdout\n(line: 20) OK stdout\n",
      expected_err: "(line: 2) ERR stderr\n(line: 4) ERR stderr\n(line: 5) ERR stderr\n(line: 6) ERR stderr\n(line: 7) ERR stderr\n(line: 9) ERR stderr\n(line: 10) ERR stderr\n(line: 11) ERR stderr\n(line: 19) ERR stderr\n",
    }

    {:ok, state: Basic.new(), sample: sample, }
  end

  test "put with function", %{state: state, } do
    # stderr: nil
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: nil,
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 0

    # stderr: false
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: false,
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 0

    # stderr: ""
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: "",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 0

    # status_raw: 0, but stderr is truthy
    state = Map.merge(state, %{
      status_raw: 0,
      stderr: "foo",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 1

    # status_raw: not 0, and stderr not empty neither falsey
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: "foo",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 25

    # Other scenarios
    # stderr: 0
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: 0,
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 25
  end

  test "merge_output" do
    stdout = [{1, "One"}, {3, ""}, ]
    stderr = [{2, "Two"}, {4, "Four"}, {6, "Six"}, ]
    merged = [{1, :stdout, "One"}, {2, :stderr, "Two"}, {3, :stdout, ""}, {4, :stderr, "Four"}, {6, :stderr, "Six"}]

    assert merge_output(stdout, stderr) == merged
    assert :cond_clause = catch_error(merge_output(stdout ++ [{5, nil}], stderr))

    assert merge_output(stdout, []) == Enum.filter(merged, fn {_, :stdout, _}-> true; _ -> false; end)
    assert merge_output([], stderr) == Enum.filter(merged, fn {_, :stderr, _}-> true; _ -> false; end)
    catch_error(merge_output([{9, "Nine"}, {1, "One"}], [""]))
  end

  test "list_commands" do
    assert list_commands() |> Enum.member?(:sample) == true
    refute list_commands() |> Enum.member?(:this_file_doenst_exist) == true
  end

  test "local_config" do
    assert is_list( local_config() ) == true
    assert is_map( local_config()[:sample] ) == true
    assert is_map( local_config(:sample) ) == true
    assert local_config(:sample)[:title] != ""
  end

  test "module_config" do
    assert is_map( module_config(:sample) ) == true
    assert is_map( module_config([:sample])[:sample] ) == true
  end

  test "merge_config" do
    assert is_map( merge_config(:sample) ) == true
    assert merge_config(:sample).title != ""
 end
end