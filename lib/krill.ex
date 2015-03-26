defmodule Krill do
  require Logger
  use Behaviour
  defcallback new() :: map
  defcallback config() :: map
  defcallback run() :: tuple
  defcallback capture(map) :: map
  defcallback process_std(map) :: map
  defcallback output(map) :: nil | :ok | :error

  defmacro __using__(_opts) do
    quote do
      use Application
      require Logger
      import Krill
      import Krill.Macro
      require Krill.Process
      alias Krill.Parser

      @behaviour Krill

      defmodule Command do
        defstruct [
          # configurable
          command: nil,
          command_name: nil,
          message_ok: "OK: Everything is alright.",
          message_error: "ERROR: Errors have been found.",
          accept: %{stdout: nil, stderr: nil},
          reject: %{stdout: nil, stderr: nil},

          # non-configurable
          input: nil,
          stdout: [], stdout_raw: [],
          stderr: [], stderr_raw: [],
          output: [],
          process: nil,
          result: nil,
          status: nil, status_raw: nil,
        ]
      end

      def config(), do: %{}
      def capture(state), do: state
      def process_std(state), do: state

      def new(conf \\ nil) when is_nil(conf) when is_map(conf) do
        if is_nil(conf), do: conf = config()

        unless Enum.empty?(conf) do
          Map.merge(%Command{}, conf)
        else
          %Command{}
        end
      end

      def start(_type, _args), do: run()

      def run() do
        state = new()
        IO.puts "Running #{state.command_name}"
        IO.puts "$ #{state.command}\n"

        {:ok, state} = Krill.Process.run(state)
        
        :ok = state
          |> capture()
          |> process_std
          |> put(:status, &Krill.Process.determine_status/1)
          |> output

        #Logger.debug "FINAL STATE [run]: #{inspect(state)}"
        #IO.inspect(state)
        {:ok, state}
      end

      def output(state) do
        # Merge output
        merge_output(state.stdout, state.stderr)

        case state.status do
          0 ->
            IO.puts( state.message_ok )
          _ ->
            IO.puts( :stderr, state.message_error )
        end

        :ok
      end

      defoverridable [config: 0, start: 2, new: 0, process_std: 1, capture: 1, run: 0, ]
    end
  end

  # Temporary function, just to display message
  # I NEED TO IMPORVE this.
  def merge_output(stdout, stderr) do
    #IO.inspect(stdout)
    #IO.inspect(stderr)

    result = Enum.sort(Keyword.keys(stdout) ++ Keyword.keys(stderr)) |> 
      Enum.map( fn(key)->

        # return the value of collection[:key]
        find = fn(collection, key) ->
          Enum.find_value(
            collection,
            #fn({line_no, line}) when line_no == key -> line end
            fn({line_no, line})-> if line_no == key, do: line end
          )
        end

        #k = :"#{key}"
        cond do
          val = find.(stdout, key) ->
            {key, :stdout, val}

          val = find.(stderr, key) ->
            {key, :stderr, val}

          true ->
            nil
        end
      end )

    #Logger.debug("RESULT")
    #IO.inspect(result)
    Enum.each(result, fn({_line_no, type, line}) ->  
      case type do
        :stdout ->
          IO.puts( line )

        :stderr ->
          IO.puts( :stderr, line)
      end
    end)
  end

  @doc "Put field, value pair into state"
  def put(state, field, fn_value) when is_function(fn_value) do
    Map.put(state, field, fn_value.(state))
  end

end