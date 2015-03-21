defmodule Krill.ServerTest do
  use ExUnit.Case
  doctest Krill.Server
  alias Krill.Server
  use Krill

  setup do
    {:ok, pid} = start_link
    :ok = new(pid)
    state = Server.state(pid)
    {:ok, pid: pid, state: state, }
  end

  test "Server.put with function", %{pid: pid, } do
    # stderr: nil
    Server.merge(pid, %{
      status_raw: 25,
      stderr: nil,
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 0

    # stderr: false
    Server.merge(pid, %{
      status_raw: 25,
      stderr: false,
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 0

    # stderr: ""
    Server.merge(pid, %{
      status_raw: 25,
      stderr: "",
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 0

    # status_raw: 0, but stderr is truthy
    Server.merge(pid, %{
      status_raw: 0,
      stderr: "foo",
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 1

    # status_raw: not 0, and stderr not empty neither falsey
    Server.merge(pid, %{
      status_raw: 25,
      stderr: "foo",
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 25

    # Other scenarios
    # stderr: 0
    Server.merge(pid, %{
      status_raw: 25,
      stderr: 0,
    })
    Server.put(pid, :status, &Server.determine_status/1)
    assert Server.get(pid, :status) == 25

  end
end
