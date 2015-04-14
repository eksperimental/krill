defmodule Command do
  defstruct [
    # configurable
    title:         nil,
    module:        nil,
    command:       nil,
    command_name:  nil,
    timeout:       5000,
    message_ok:    "OK: Everything is alright.",
    message_error: "ERROR: Errors have been found.",
    accept:        %{stdout: nil, stderr: nil},
    reject:        %{stdout: nil, stderr: nil},

    # non-configurable
    input:      nil,
    stdout:     [],
    stdout_raw: [],
    stderr:     [],
    stderr_raw: [],
    process:    nil,
    result:     nil,
    status:     nil,
    status_raw: nil,
  ]
  
  @typedoc "Command struct"
  @type t :: %Command{
    title:         nil | String.t,
    module:        nil | String.t,
    command:       nil | String.t,
    command_name:  nil | String.t,
    timeout:       non_neg_integer | :infinity,
    message_ok:    nil | String.t,
    message_error: nil | String.t,
    accept:        %{stdout: (nil | String.t), stderr: (nil | String.t)},
    reject:        %{stdout: (nil | String.t), stderr: (nil | String.t)},

    # non-configurable
    input:      nil | String.t,
    stdout:     [Krill.std_line],
    stdout_raw: [Krill.std_line],
    stderr:     [Krill.std_line],
    stderr_raw: [Krill.std_line],
    process:    nil | Porcelain.Process.t,
    result:     nil | Porcelain.Result.t,
    status:     nil | non_neg_integer,
    status_raw: nil | non_neg_integer,
  }
end

defmodule Krill do
  @moduledoc """
  `Krill` is a filter feeder that executes a shell command, and filters stdout and
  stderr, according to rules set in the child module. Letting us get rid of
  commands that will output exit with an error message and error status, and
  being able to use this in Continuous Integration or other projects where
  need our commands to return 0.
  """

  require Logger
  use Behaviour

  @typedoc "Standard line"
  @type std_line :: {pos_integer, String.t}

  @typedoc "Standard line with status"
  @type std_line_status :: {pos_integer, (:stdout | :stderr), String.t}

  defcallback new(nil | map | Command.t) :: Command.t
  defcallback config() :: map
  defcallback run(nil | map | Command.t) :: {atom, Command.t}
  defcallback postprocess(Command.t) :: Command.t
  defcallback process(Command.t) :: Command.t
  defcallback postprocess(Command.t) :: Command.t
  defcallback output(Command.t) :: :ok | :error

  @status_ok 0
  #@status_error_generic 1
  
  defmacro __using__(_opts) do
    quote do
      require Logger
      use Application
      import Krill
      require Krill.Process
      alias Krill.Parser

      @behaviour Krill

      @status_ok unquote(@status_ok)

      @doc false
      def start(_type, _args), do: {:ok, self()}

      @doc "Gets the module name of the module invoking the `use` macro."
      def get_module, do: __MODULE__

      @doc """
      Creates a basic configuration for the command. Such as setting `command`, 
      `accept` and `reject` rules, and success or error messages.
      """
      def config(), do: %{}
      
      @doc """
      Create a new command merging the values of `conf` into the default
      configs and the ones set int `config/config.exs`

      Returns a map with the state
      """
      @spec new(nil | map | Command.t) :: Command.t
      def new(conf \\ nil) when is_nil(conf) when is_map(conf) do
        result = Map.merge(%Command{}, config())
        if conf,
          do: result = Map.merge(result, conf)

        Map.put(result, :module, __MODULE__)
        |> Map.put(:name, {:global, __MODULE__})
      end

      @doc """
      Runs the command.

      Returns a tuple with {:ok, state}
      """
      @spec run(nil | map | Command.t) :: {(:ok | :error), Command.t}
      def run(conf \\ nil) do
        #IO.inspect(conf)
        state = new(conf)
        #IO.puts("RUN STATE")

        #check basic information is provided, such as command
        if empty?(state.command),
          do: exit({:shutdown, "command not provided", state})

        if state.title != "",
          do: IO.puts "Running: #{state.title}"

        IO.puts "$ #{state.command}\n"
        {:ok, state} = Krill.Process.run(state)
        
        state = state
          |> preprocess
          |> process
          |> put(:status, &Krill.Process.determine_status/1)
          |> postprocess

        :ok = output(state)

        #Logger.debug "FINAL STATE [run]: #{inspect(state)}"
        #IO.inspect(state)
        {:ok, state}
      end

      @doc """
      Preprocess `state`, right before it is sent to `process`.
      """
      @spec preprocess(Command.t) :: Command.t
      def preprocess(state), do: state

      @doc """
      The main function of this callback is to add the :stdout and :stderr to
      the %Command{} struct given.
      """      
      @spec process(Command.t) :: Command.t
      def process(state), do: state

      @doc """
      This is a post processing operation, the last one before messages are going to
      be printed.

      Here's where you will usually write your `message_ok` and `message_error` based on
      the results produced by `process`.
      """
      @spec postprocess(Command.t) :: Command.t
      def postprocess(state), do: state

      @doc """
      Outputs `state` on screen, sending message to `stdout` and `stderr`.

      Returns `:ok`  
      """
      @spec output(Command.t) :: :ok | :error
      def output(state) when is_map(state) do
        merge_output(state.stdout, state.stderr) |> print_output

        case state.status do
          @status_ok ->
            IO.puts( state.message_ok )
          _ ->
            IO.puts( :stderr, state.message_error )
        end

        :ok
      end

      defoverridable [config: 0, new: 0, preprocess: 1, process: 1, postprocess: 1, run: 1, ]
    end
  end

  @doc """
  Checks if `value` is a falsey value, an empty string or an empty list.  
  """
  @spec empty?(term) :: boolean
  def empty?(value)
    when value == ""
    when value == []
    when value == false
    when is_nil(value),
    do: true

  def empty?(_value), do: false

  @doc """
  Merge tuple lists `stdout` and `stderr` with format {line_no, msg}, into a new tuple
  list with format `{line_no, std_type, msg}` being std_type either :stdout or :stderr
  """
  @spec merge_output([std_line], [std_line]) :: [std_line_status]
  def merge_output(stdout, stderr) when is_list(stdout) and is_list(stderr) do
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

  @doc """
  Prints `merged_output` to :stdout and :stderr
  """
  @spec print_output([std_line_status]) :: :ok
  def print_output(merged_output) do
    Enum.each( merged_output,
      fn({_line_no, type, line}) ->  
        case type do
          :stdout ->
            IO.puts( line )

          :stderr ->
            IO.puts( :stderr, line)
        end
      end)
    :ok
  end


  @doc "Put field, value pair into state"
  @spec put(map, term, term) :: map
  def put(state, field, fn_value) when is_function(fn_value) do
    Map.put(state, field, fn_value.(state))
  end

  
  @doc "Returns a list of atoms for every Command module"  
  @spec list_commands(String.t) :: [atom]
  def list_commands(dir \\ "./lib/command") do
    {:ok, files} = File.ls(dir)
    Enum.map( files, &(Path.basename(&1, ".ex") |> String.to_atom) )
  end


  @doc "Returns the local config map, stored in config/config.exs"
  @spec local_config() :: term
  @spec local_config(atom) :: term
  def local_config,
    do: Application.get_env(:krill, :config)

  def local_config(item) when is_atom(item),
    do: local_config()[item]


  @doc "Returns the configuration for `item`, by running the new function in the given module"
  @spec module_config(atom) :: Command.t
  @spec module_config([atom]) :: [{atom, Command.t}]

  def module_config(item) when is_atom(item) do
    module = Module.concat([Command, String.capitalize("#{item}")])
    apply(module, :new, [])
  end

  def module_config(items) when is_list(items),
    do: Enum.map(items, &{&1, module_config(&1)})


  @doc "Given the module `item`, it returns a merged map of the local config into the module config"
  @spec merge_config(atom) :: Command.t 
  def merge_config(item) when is_atom(item),
    do: Map.merge( module_config(item), local_config(item) )

end