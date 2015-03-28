defmodule Command.Sample do
  use Krill

  def config do
    command_name = "Sample Command"
    %{ 
      name: {:global, __MODULE__},
      command_name: command_name,
      command: "./test/fixtures/echo.sh",
      reject: [
        stdout: [
          "foobar",
          "line: 18",
        ],
        stderr: [
          "foobar",
          "line: 12",
        ]
      ],
      # These messages are not needd. it is just nice to include the command name
      message_ok: "OK: #{command_name} - Documents have been validated.",
      message_error: "ERROR: #{command_name} - Errors have been found.",
    }
  end

  def process_std(state) do
    stdout = Parser.reject(state.stdout_raw, state.reject[:stdout])
    stderr = Parser.reject(state.stderr_raw, state.reject[:stderr])
    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end
  
end