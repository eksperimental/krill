defmodule PorcelainExample do
  @state {:global, __MODULE__}
  use Application

  alias Porcelain.Process
  alias Porcelain.Result

  # AGENT
  def start_link,
  do: Agent.start_link(fn -> HashDict.new end, name: @state)

  def state(id),
  do: Agent.get(@state, &Dict.get(&1, id))

  def state(id, message),
  do: Agent.update(@state, &Dict.put(&1, id, message))


  # COUNTER
  # get
  defp counter, do: state(:counter)
  # update
  defp counter(n), do: state(:counter, n)
  def counter_increase do
    result = counter + 1
    :ok = state(:counter, result)
    result
  end

  def start(_, _) do
    start_link
    counter(1)

    run()
    {:ok, self()}
  end

  def run() do

    input = "ab\nbc\ncd\nbe\nbf\nde\nbc\nef\n"
    IO.write """
    Launching external program:
      sort
    Input:
    #{input}

    Output:
    """
    instream = input |> String.split("\n") |> Stream.map(&(&1)<>"\n")

    # Porcelain.spawn("perl", ["-pe", "s/^/#{counter_increase}|/"], opts)
    cmd = "grep"
    args = ["b"]
    opts = [
      in: input,
      out: {:send, self()},
      err: {:send, self()}
    ]
    %Process{pid: pid} = Porcelain.spawn(cmd, args, opts)
    handle_output(pid)
  end

  def handle_output(pid) do
    receive do
      {^pid, :data, :out, data} ->
        IO.puts "stdout:\n#{data}"
        handle_output(pid)
      {^pid, :data, :err, data} ->
        IO.puts "stderr:\n#{data}"
        handle_output(pid)
      {^pid, :result, %Result{status: status}} ->
        IO.puts "status:\n#{status}"
    after
      5_000 -> IO.puts "timeout"
    end
  end

end
