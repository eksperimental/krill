defmodule Krill.Sample do
  use Krill

  def config do
    %{ 
      name: {:global, __MODULE__},
      command_name: "Sample Command",
      #command: "echo 'foo bar'; echo 'bad' >&2",
      command: "./lib/krill/sample.sh",
      reject: [
        stdout: [
          "foobar",
        ],
        stderr: [
          "foobar",
        ]
      ],
    }
  end

  def process_std(pid) do
    stdout = Server.get(pid, :stdout_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stdout])
    Server.put(pid, :stdout, stdout)

    stderr = Server.get(pid, :stderr_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stderr])
    Server.put(pid, :stderr, stderr)

    :ok
  end
  
end