defmodule KrillTest do
  use ExUnit.Case, async: true
  require Logger
  import Krill
  require Version

  doctest Krill

  defmodule Command.Basic, do: use Krill
  alias Command.Basic

  @status_ok    0
  @status_error_generic 1

  setup do
    sample = %{
      conf: local_config(:sample),
    }

    {:ok, state: Basic.new(), sample: sample, }
  end

  test "put with function & Krill.Process.determine_status", %{state: state, } do
    # stderr: nil
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: nil,
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == @status_ok 

    # stderr: false
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: false,
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == @status_ok 

    # stderr: ""
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: "",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == @status_ok 

    # status_raw: @status_ok, but stderr is truthy
    state = Map.merge(state, %{
      status_raw: @status_ok,
      stderr: "foo",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == @status_error_generic

    # status_raw: not 0, and stderr not empty neither falsey
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: "foo",
    })
    state = put(state, :status, &Krill.Process.determine_status/1)
    assert state.status == 25

    # Other scenarios
    # stderr: @status_ok 
    state = Map.merge(state, %{
      status_raw: 25,
      stderr: @status_ok,
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
    assert local_config(:sample).title != ""
  end

  test "module_config" do
    assert is_map( module_config(:sample) ) == true
    assert is_map( module_config([:sample])[:sample] ) == true
  end

  test "merge_config" do
    assert is_map( merge_config(:sample) ) == true
    assert merge_config(:sample).title != ""
  end

  test "version" do
    assert is_bitstring(version()) != version()

    {:ok, v} = Version.parse(version())
    assert v != ""
  end

  test "app name" do
    assert "krill" == app
  end

end