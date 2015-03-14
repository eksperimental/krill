defmodule Krill.Execute do
  import Krill, only: [state: 1, state: 2, ]
  alias Porcelain.Process
  alias Porcelain.Result

  # COUNTER
  # get
  def counter(dict), do: state(dict, :counter)
  # update
  def counter(dict, n), do: state(dict, :counter, n)
  def counter_increase(dict) do
    result = counter(dict) + 1
    :ok = state(dict, :counter, result)
    result
  end

  def timestamp_microseconds do
    {mega, sec, micro} = :os.timestamp
    ((mega * 1000000 + sec) * 1000000)+micro
  end

  # PORCELAIN
  def exec(dict, command, input \\ nil) do
    opts = [
      out: {:send, self()},
      err: {:send, self()}
    ]
    
    unless is_nil(input),
    do: opts = [input: input] ++ opts

    %Process{pid: pid} = Porcelain.spawn_shell(command, opts)
    handle_output(dict, pid)
  end

  def handle_output(dict, pid) do
    receive do
      {^pid, :data, :out, data} ->
        state(dict, :stdout_raw, data)
        handle_output(dict, pid)
      {^pid, :data, :err, data} ->
        state(dict, :stderr_raw, data)
        handle_output(dict, pid)
      {^pid, :result, %Result{status: status}} ->
        IO.puts "status:\n#{status}"
        capture
        process_std
    #after
    #  5_000 -> IO.puts "timeout"
    end
  end

end