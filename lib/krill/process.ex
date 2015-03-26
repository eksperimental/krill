defmodule Krill.Process do
  alias Porcelain.Result
  require Logger

  @moduledoc """
  Deals with anything related to Porcelain.Process and Results
  """
  
  def run(state, _timeout \\ :infinity) do
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
        #Logger.debug inspect(state)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  # def terminate(reason, _state) do
  #   Logger.debug "Process Terminated. Reason: #{inspect reason}"
  #   #Logger.debug "State: #{inspect(_state)}"
  #   :ok
  # end

  def handle_output(sender, pid, state, counter \\ 1) do
    receive do
      # state = %{a: 1, b: 2, stdout_raw: %{stdout: %{1 => "some string"}}}
      # put_in(state, [:stdout_raw, :stdout, 2],  "ssss")

      { ^pid, :data, :out, data } ->
        #Logger.debug "OUT: #{inspect(data)}"
        {_, state_updated} = get_and_update_in( state.stdout_raw, &({&1, &1 ++ [{counter, data}] }) )
        handle_output( sender, pid, state_updated, counter+1)

      { ^pid, :data, :err, data } ->
        {_, state_updated} = get_and_update_in( state.stderr_raw, &({&1, &1 ++ [{counter, data}] }) )
        handle_output( sender, pid, state_updated, counter+1)

      { ^pid, :result, result=%Result{status: status} } ->
        state = Map.merge(state, %{status_raw: status, result: result})
        #IO.puts "State (handle_output): #{inspect(state)}"
        send sender, { :ok, state }
    end
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

end