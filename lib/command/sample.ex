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
          "line: 4",
        ]
      ],
    }
  end

  def process_std(state) do
    #Logger.debug("STATE:")
    #IO.inspect(state)
    stdout = Parser.reject(state.stdout_raw, state.reject[:stdout])
    stderr = Parser.reject(state.stderr_raw, state.reject[:stderr])

    #Logger.debug "STDOUT:"
    #IO.inspect(stdout)
    #Logger.debug "STDERR:"
    #IO.inspect(stderr)
    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end
  
end