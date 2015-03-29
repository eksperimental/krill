defmodule Krill.Process do
  alias Porcelain.Result
  require Logger
  import Krill.Macro

  @moduledoc """
  Deals with anything related to Porcelain.Process and Results
  """  
  def run(state, timeout \\ :infinity) do
    case state.process do
      nil ->
        #Logger.debug("PID: #{inspect self}")
        opts = [ out: {:send, self}, err: {:send, self}, ]
        %Porcelain.Process{pid: pid} = process = Porcelain.spawn_shell(state.command, opts)
        _state_handled = handle_output(self, pid, state)
        receive do
          {:ok, state} ->
            state = state
          
          after timeout ->
            exit(:timeout)
        end
        state = Map.put(state, :process, process)
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end


  def handle_output(sender, pid, state, counter \\ 1) do
    receive do
      { ^pid, :data, :out, data } ->
        #Logger.debug(data)
        {data_lines, counter_updated} = get_multiline_data(data, counter)
        {_, state_updated} = get_and_update_in( state.stdout_raw, &({&1, &1 ++ data_lines }) )
        handle_output(sender, pid, state_updated, counter_updated)

      { ^pid, :data, :err, data } ->
        #Logger.debug(data)
        {data_lines, counter_updated} = get_multiline_data(data, counter)
        {_, state_updated} = get_and_update_in( state.stderr_raw, &({&1, &1 ++ data_lines }) )
        handle_output( sender, pid, state_updated, counter_updated)

      { ^pid, :result, result=%Result{status: status} } ->
        state = Map.merge(state, %{status_raw: status, result: result})
        send sender, { :ok, state }
    end
  end

  defp get_multiline_data(data, counter) do
    Enum.map_reduce( String.split( String.rstrip(data, ?\n), "\n"), counter,
      &{{&2, &1}, &2+1}
    )
  end


  def determine_status(state) do
    cond do
      empty?(state.stderr) ->
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