defmodule KrillTest do
  use ExUnit.Case, async: true
  doctest Krill
  use Krill

  setup do
    {:ok, state: new(), }
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
end
