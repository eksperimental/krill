defmodule Command.Sample do
  @moduledoc """
  `Command.Sample` is very basic `Krill` module that only applies creates
  a comand, with some reject rules and customized success and error messages.
  """

  use Krill

  def config do
    command_name = "echo.sh"
    %{
      #command: "./test/fixtures/echo.sh",
      title: "Sample Command",
      command_name: command_name,
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
      # These messages are not needed. it is just nice to include the command name
      message_ok: "OK: #{command_name} - Documents have been validated.",
      message_error: "ERROR: #{command_name} - Errors have been found.",
    }
  end

  def process(state) do
    stdout = Parser.reject(state.stdout_raw, state.reject[:stdout])
    stderr = Parser.reject(state.stderr_raw, state.reject[:stderr])
    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end
  
end