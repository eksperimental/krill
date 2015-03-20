defmodule Krill.Sample do
  use Krill, name: {:global, __MODULE__}
  use Application
  
  @command_name "Sample Command"
  @command      "echo 'foo bar'"

  def new(pid) do
    Server.put(pid, :command, @command)
    Server.put(pid, :command_name, @command_name)

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
    stdout = Server.get(pid, :stdout_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stdout])
    Server.put(pid, :stdout, stdout)

    stderr = Server.get(pid, :stderr_raw) |>
      Parser.reject(Server.get(pid, :reject)[:stderr])
    Server.put(pid, :stderr, stderr)

    :ok
  end

  def start(_type, _args), do: run()
end