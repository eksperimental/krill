defmodule Command.Sample do
  use Krill

  def config do
    %{ 
      name: {:global, __MODULE__},
      command_name: "Sample Command",
      #command: "echo 'foo bar'",
      command: "./test/command/sample.sh",
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

  def process_std(state) do
    stdout = Parser.reject(state.stdout_raw, state.reject[:stdout])
    stderr = Parser.reject(state.stderr_raw, state.reject[:stderr])
    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end
  
end