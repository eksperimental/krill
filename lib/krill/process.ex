defmodule Krill.Process
  alias Porcelain.Result
  require Logger

  @moduledoc """
  Deals with anything related to Porcelain.Process and Results
  """

  def run(state, timeout \\ :infinity) do
    case state[:process] do
      nil ->
        process = do_process(state, state.command, state.input)
        #Logger.debug("process: #{inspect process}")
        Porcelain.Process.await(process, :infinity)
        Map.put(state, :process, process)

      _ ->
        state
    end

  end

  def terminate(reason, _state) do
    Logger.debug "Process Terminated. Reason: #{inspect reason}"
    #Logger.debug "State: #{inspect(_state)}"
    :ok
  end

  #####
  # Internal Functions
  def do_process(pid, command, input) do
    opts = [ out: {:send, pid}, err: {:send, pid}, ]

    unless is_nil(input),
    do: opts = [input: input] ++ opts

    Porcelain.spawn_shell(command, opts)
  end

  def determine_status(state) do
    cond do
      !(state.stderr) ->
        0
      "" == state.stderr ->
        0
      # status_raw is 0, but stderr neither empty, nor falsey
      state.status_raw == 0 ->
        1
      # set same as status_raw
      true ->
        state.status_raw
    end
  end

  #####
  # GenServer implementation

  def handle_info(_info={_pid, :data, :out, data}, state) do
    { :noreply, Map.put(state, :stdout_raw, "#{state.stdout_raw}\n#{data}") }
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    { :noreply, Map.put(state, :stderr_raw, "#{state.stderr_raw}\n#{data}") }
  end
 
  def handle_info(_info={_pid, :result, result=%Result{status: status}}, state) do
    { :noreply, Map.merge(state, %{status_raw: status, result: result}) }
  end