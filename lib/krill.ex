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

      def get_module do
        #quote do: __MODULE__
        __MODULE__
      end

      defmodule Command do
        defstruct [
          # configurable
          title: nil,
          module: nil,
          command: nil,
          command_name: nil,
          timeout: 5000,
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
        result = Map.merge(%Command{}, config())
        if conf,
          do: result = Map.merge(result, conf)

        Map.put(result, :module, __MODULE__)
        |> Map.put(:name, {:global, __MODULE__})
      end

      #def start(_type, _args), do: run()
      def start(_type, _args), do: nil

      def run(conf \\ nil) do
        #IO.inspect(conf)
        state = new(conf)
        #IO.puts("RUN STATE")

        #check basic information is provided, such as command
        if empty?(state.command),
          do: exit({:shutdown, "command not provided", state})

        if state.title,
          do: IO.puts "Running: #{state.title}"

        IO.puts "$ #{state.command}\n"
        {:ok, state} = Krill.Process.run(state)
        
        state = state
          |> capture()
          |> process_std
          |> put(:status, &Krill.Process.determine_status/1)

        output(state)

        #Logger.debug "FINAL STATE [run]: #{inspect(state)}"
        #IO.inspect(state)
        {:ok, state}
      end

      def output(state) when is_map(state) do
        print_output( merge_output(state.stdout, state.stderr) )

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

  def merge_output(stdout, stderr) when is_list(stdout) and is_list(stderr) do
    #stdout and stderr are in the format: [{line_no, line}, ...]

    # return the value of collection[:key]
    find = fn(collection, key) ->
      Enum.find_value(
        collection,
        fn({line_no, line})-> if line_no == key, do: line end
      )
    end

    Enum.sort(Keyword.keys(stdout) ++ Keyword.keys(stderr))
      |> Enum.map( fn(key)->
        cond do
          val = find.(stdout, key) ->
            {key, :stdout, val}

          val = find.(stderr, key) ->
            {key, :stderr, val}
        end
      end )
  end

  def print_output(merged_output) do
    # Merge output
    Enum.each( merged_output,
      fn({_line_no, type, line}) ->  
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
  
  @doc "Returns a list of atoms for every Command module"  
  def list_commands(dir \\ "./lib/command") do
    {:ok, files} = File.ls(dir)
    Enum.map( files, &(Path.basename(&1, ".ex") |> String.to_atom) )
  end

  @doc "Returns the local config map, stored in config/config.exs"
  def local_config,
    do: Application.get_env(:krill, :config)

  def local_config(item) when is_atom(item),
    do: local_config()[item]

  @doc "Returns the configuration for `item`, by running the new function in the given module"
  def module_config(item) when is_atom(item) do
    module = Module.concat([Command, String.capitalize("#{item}")])
    apply(module, :new, [])
  end

  def module_config(items) when is_list(items),
    do: Enum.map(items, &{&1, module_config(&1)})

  @doc "Given the module `item`, it returns a merged map of the local config into the module config"
  def merge_config(item) when is_atom(item),
    do: Map.merge( module_config(item), local_config(item) )

end