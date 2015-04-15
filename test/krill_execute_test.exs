defmodule Krill_ExecuteTest do
  use ExUnit.Case, async: false
  require Command.Sample
  require Logger
  import Krill
  import ExUnit.CaptureIO

  setup do
    conf  = local_config(:sample)
    {:ok, conf: conf}
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

  test "Krill.execute one task", %{conf: conf} do
    assert capture_io(fn ->
      Command.Sample.run(conf)
    end) == capture_io(fn ->
      execute(["sample"])
    end)

    assert capture_io(:stderr, fn ->
      Command.Sample.run(conf)
    end) == capture_io(:stderr, fn ->
      execute(["sample"])
    end)
  end
  
  #test "Krill.execute :config" do
  #  assert execute([":config"]) == {:ok, %{}}
  #  assert execute([":all"]) == {:ok, %{}}
  #  assert execute(["sample"]) == {:ok, %{}}
  #end

end
