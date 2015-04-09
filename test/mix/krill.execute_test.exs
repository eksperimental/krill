defmodule Krill.ExecuteTest do
  use ExUnit.Case, async: true
  require Command.Sample
  require Logger
  import Krill
  import ExUnit.CaptureIO  

  setup do
    conf  = local_config(:sample)
    {:ok, state} = Command.Sample.run(conf)
    {:ok, conf: conf, state: state, }
  end

  test "Mix.Tasks.Krill.Execute.run(:sample)", %{conf: conf} do
    assert capture_io(fn ->
      Command.Sample.run(conf)
    end) == capture_io(fn ->
      Mix.Tasks.Krill.Execute.run(["sample"])
    end)

    assert capture_io(:stderr, fn ->
      Command.Sample.run(conf)
    end) == capture_io(:stderr, fn ->
      Mix.Tasks.Krill.Execute.run(["sample"])
    end)
  end
  
end
