defmodule Krill.Sample do
  use Krill, name: {:global, __MODULE__}
  @command_name "Sample Command"

  def new(pid) do
    Server.put(pid, :command, "echo 'foo bar'")

    Server.put(pid, :reject, [
      stdout: [
        "foobar",
      ],
      stderr: [
        "foobar",
      ]
    ])

    :ok
  end

  def process_std(pid) do
    #stdout
    #IO.puts inspect(Server.get(pid, :stdout_raw))

    stdout = Server.get(pid, :stdout_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stdout])
    Server.put(pid, :stdout, stdout)

    stderr = Server.get(pid, :stderr_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stderr])
    Server.put(pid, :stderr, stderr)

    :ok
  end

end