defmodule Krill.Process do
  alias Porcelain.Result
  require Logger

  @moduledoc """
  Deals with anything related to Porcelain.Process and Results
  """
  
  def run(state, timeout \\ :infinity) do
    case state.process do
      nil ->
        Logger.debug("PID: #{inspect self}")
        
        %Porcelain.Process{pid: pid} = process = spawn_process(self, state)
        state = handle_output(pid, state, timeout)
        Logger.debug("process: #{inspect process}")
        {:ok, _result} = Porcelain.Process.await(process, timeout)

        Logger.debug inspect(state)
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
  def spawn_process(pid, state) do
    opts = [ out: {:send, pid}, err: {:send, pid}, ]

    unless is_nil(state.input),
    do: opts = [input: state.input] ++ opts

    process = Porcelain.spawn_shell(state.command, opts)
    #{:ok, _result} = Porcelain.Process.await(process, timeout)
    process
  end

  def do_process(pid, state) do
    #opts = [ out: {:send, pid}, err: {:send, pid}, ]
    opts = []

    unless is_nil(state.input),
    do: opts = [input: state.input] ++ opts

    Porcelain.shell(state.command, opts)
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

  def handle_output(pid, state, timeout \\ :infinity) do
    receive do
      {^pid, :data, :out, data} ->
         handle_output( pid, Map.put(state, :stdout_raw, "#{state.stdout_raw}\n#{data}"), timeout)

      {^pid, :data, :err, data} ->
        handle_output( pid, Map.put(state, :stderr_raw, "#{state.stderr_raw}\n#{data}"), timeout)

      {^pid, :result, result=%Result{status: status}} ->
        Map.merge(state, %{status_raw: status, result: result})
    after
      timeout -> IO.puts( :stderr, "timeout" )
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
end