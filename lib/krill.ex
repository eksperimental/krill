defmodule Krill do
  use Behaviour
  defcallback process_std(state) :: map
  defcallback new :: map
  defcallback config() :: map

  defmacro __using__(_opts) do
    quote do
      use Application
      require Logger
      import Krill
      import Krill.Macro
      alias Krill.State
      alias Krill.Parser
      @behaviour Krill

      defmodule Command do
        defstruct [
          # configurable
          command: nil,
          command_name: nil,
          message_ok: "OK: Everything is alright.",
          message_error: "ERROR: Errors have been found.",
          accept: [stdout: nil, stderr: nil],
          reject: [stdout: nil, stderr: nil],

          # non-configurable
          input: nil,
          stdout: nil, stdout_raw: nil,
          stderr: nil, stderr_raw: nil,
          process: nil,
          result: nil,
          status: nil, status_raw: nil,
        ]
      end

      def config(), do: %{}
      def process_std(state), do: state
      def capture(state), do: state

      def new do
        unless Enum.empty?(conf = config()) do
          Command.merge(%Command{}, conf)
        else
          %Command{}
        end
      end

      def start(_type, _args), do: run()

      def run() do
        state = new()
        Logger.debug "Running #{state.command_name}"
        Logger.debug "$ #{state.command}"

        state = Krill.Process.run(state)
        |> capture
        |> process_std
        |> put(:status, &Krill.Process.determine_status/1)
        |> output

        Logger.debug "FINAL STATE [run]: #{inspect(state)}"

        {:ok, state}
      end

      def output(state) do
        case state.status do
          0 ->
            IO.puts state.message_ok
          _ ->
            IO.puts state.message_error
        end

        unless empty? state.stdout  do
          Logger.debug "STDOUT"
          IO.puts( state.stdout )
        end

        unless empty? state.stderr do
          Logger.debug "STDERR"
          IO.puts( :stderr, state.stderr )
        end

        :ok
      end

      def debug do
        # {:ok, pid}  = start_link()
        # :ok = new(pid)
        # Logger.debug "pid [debug]: #{inspect(pid)}"
        # state = Server.state(pid)
        # Logger.debug "state [debug]: #{inspect(state)}"
        # #Logger.debug("self() [debug]: #{inspect self}")
        #
        # process = Server.do_process(pid, state.command, state.input)
        # #Logger.debug("process: #{inspect(process)}")
        # Porcelain.Process.await(process, :infinity)
        # final_state = Server.state(pid)
        # #Logger.debug("FINAL STATE [run]: #{inspect(final_state)}")
        # {:ok, pid, final_state}
      end

      defoverridable [config: 0, start: 2, new: 1, process_std: 1, capture: 1, run: 0, ]
    end
  end

  @doc "Put field, value pair into state"
  def put(state, field, fn_value) when is_function(fn_value) do
    Map.put(state, field, fn_value.(state))
  end

end