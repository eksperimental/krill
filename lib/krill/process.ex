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
        opts = [ out: {:send, self}, err: {:send, self}, ]
        %Porcelain.Process{pid: pid} = process = Porcelain.spawn_shell(state.command, opts)
        _state_handled = handle_output(self, pid, state)
        #Porcelain.Process.await(process, timeout)
        receive do
          {:ok, state} ->
            state = state
        end
        state = Map.put(state, :process, process)
        Logger.debug inspect(state)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def terminate(reason, _state) do
    Logger.debug "Process Terminated. Reason: #{inspect reason}"
    #Logger.debug "State: #{inspect(_state)}"
    :ok
  end

  #####
  # Internal Functions
  def handle_output(sender, pid, state) do
    receive do
      { ^pid, :data, :out, data } ->
        #Logger.debug "OUT: #{inspect(data)}"
        handle_output( sender, pid, Map.put(state, :stdout_raw, "#{state.stdout_raw}#{data}") )

      { ^pid, :data, :err, data } ->
        #Logger.debug "ERR: #{inspect(data)}"
        handle_output( sender, pid, Map.put(state, :stderr_raw, "#{state.stderr_raw}#{data}") )

      { ^pid, :result, result=%Result{status: status} } ->
        state = Map.merge(state, %{status_raw: status, result: result})
        #IO.puts "State (handle_output): #{inspect(state)}"
        send sender, { :ok, state }
    #after
    #  :infinity -> IO.puts "timeout"
    end
  end

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
end