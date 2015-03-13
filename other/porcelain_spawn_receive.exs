alias Porcelain.Process
alias Porcelain.Result

defmodule Cmd do
  def run() do
    args = ["b"]
    opts = [
      in: "a\nb\nc\nb\nb\nd\nb\ne",
      out: {:send, self()},
      err: :out
    ]
    %Process{pid: pid} = Porcelain.spawn("grep", args, opts)
    handle_output(pid)
  end

  def handle_output(pid) do
    receive do
      {^pid, :data, :out, data} ->
        IO.puts "data: #{data}"
        handle_output(pid)
      {^pid, :data, :err, data} ->
        IO.puts "error: #{data}"
        handle_output(pid)
      {^pid, :result, %Result{status: status}} ->
        IO.puts "status: #{status}"
    after
      5_000 -> IO.puts "timeout"
    end
  end
end

Cmd.run()