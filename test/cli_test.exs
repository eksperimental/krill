defmodule Krill.CLITest do
  use ExUnit.Case, async: false
  doctest Krill.CLI
  alias Krill.CLI
  use Krill
  require Logger
  import ExUnit.CaptureIO
  require System

  setup do
    conf  = local_config(:sample)
    {:ok, conf: conf}
  end

  test "help" do
    assert capture_io(:stdio, fn ->
      CLI.help()
    end) != ""

    assert is_bitstring( capture_io(:stdio, fn ->
      CLI.help()
    end) ) == true
  end

  test "version" do
    assert capture_io(:stdio, fn ->
      CLI.version()
    end)  =~ ~r/krill version \d\.\d\.\d/
  end  

  test "--help smoke test" do
    {output, 0} = System.cmd "#{System.cwd}/krill", ~w[--help]
    assert output =~ ~r/-t,\s+--timeout\s+Timeout in milliseconds/
    refute output =~ "No command 'krill' found"
  end

end
