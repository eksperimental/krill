defmodule Krill.Basic do
  @state {:global, __MODULE__}
  use Krill, dict: @state

  @command_name "basic command"

  def new do
    state(@state, :command, "echo 'foo bar'")

    state(@state, :reject, stdout: [
      "foobar",
    ])

    state(@state, :reject, stderr: [
      "foobar",
    ])
    
    :ok
  end

  def process_std do
    #stdout
    stdout = read!(@state, :stdout_raw) |> 
      reject(@state, :stdout)
    state(@state, :stdout, stdout)

    #stderr
    stderr = read!(@state, :stderr_raw) |> 
      reject(@state, :stderr)
    state(@state, :stderr_raw, stderr)

    :ok
  end

end