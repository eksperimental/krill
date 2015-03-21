defmodule Krill do
  use Behaviour
  defcallback process_std(pid) :: any
  defcallback new(pid) :: any
  defcallback config() :: map

  defmacro __using__(_opts) do
    quote do
      use Application
      require Logger
      import Krill
      import Krill.Macro
      alias Krill.Server
      alias Krill.Parser
      @behaviour Krill

      def config(), do: %{}
      def process_std(pid), do: :ok
      def capture(pid), do: nil

      def new(pid) do
        unless Enum.empty?(conf = config()),
        do: Server.merge(pid, conf)

        :ok
      end

      def start(_type, _args), do: run()

      def start_link do
        Server.start_link(__MODULE__, %Server.Command{})
      end

      def run() do
        case start_link() do
          {:ok, pid} ->
            pid = pid
          {:error, {:already_started, pid}} ->
            pid = pid
        end
        Logger.debug "PID [run]: #{inspect(pid)}"

        :ok = new(pid)
        state = Server.state(pid)
        Logger.debug "Running #{state.command_name}"
        Logger.debug "$ #{state.command}"

        Server.get_process(pid)
        capture(pid)
        :ok = process_std(pid)
        :ok = Server.put(pid, :status, &Server.determine_status/1)
        :ok = output(pid)

        final_state = Server.state(pid)
        Logger.debug "FINAL STATE [run]: #{inspect(final_state)}"
        :ok = Server.stop(pid)

        {:ok, pid, final_state}
      end

      def output(pid) do
        state = Server.state(pid)

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
        {:ok, pid}  = start_link()
        :ok = new(pid)
        Logger.debug "pid [debug]: #{inspect(pid)}"
        state = Server.state(pid)
        Logger.debug "state [debug]: #{inspect(state)}"
        #Logger.debug("self() [debug]: #{inspect self}")

        process = Server.do_process(pid, state.command, state.input)
        #Logger.debug("process: #{inspect(process)}")
        Porcelain.Process.await(process, :infinity)
        final_state = Server.state(pid)
        #Logger.debug("FINAL STATE [run]: #{inspect(final_state)}")
        {:ok, pid, final_state}
      end

      def stop(pid) do
        Server.stop(pid)
      end

      defoverridable [config: 0, start: 2, start_link: 0, new: 1, process_std: 1, capture: 1, run: 0, stop: 1, ]
    end
  end
end

defmodule Krill.Server do
  require Logger
  use GenServer              
  alias Porcelain.Result

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

  #####
  # External API  

  def start_link(module, args) do
    GenServer.start_link(__MODULE__, args, name: {:global, module})
  end

  def get_process(pid, timeout \\ :infinity) do
    GenServer.call pid, {:get_process, pid}, timeout
  end

  @doc "Stops the server"
  def stop(pid) do
    GenServer.call pid, :stop
  end

  def terminate(reason, _state) do
    Logger.debug "Process Terminated. Reason: #{inspect reason}"
    #Logger.debug "State: #{inspect(_state)}"
    :ok
  end

  @doc "Get state"
  def state(pid) do
    GenServer.call pid, :state
  end

  @doc "Replace current_state with `new_state`"
  def state(pid, new_state) when is_map(new_state) do
    GenServer.cast pid, {:state, new_state}
  end

  @doc "Get field"
  def get(pid, field) do
    GenServer.call pid, {:get, field}
  end

  @doc "Merge `items` into current_state"
  def merge(pid, items) when is_map(items) do
    GenServer.call pid, {:merge, items}
  end

  @doc "Put field, value pair into state"
  def put(pid, field, value) do
    GenServer.cast pid, {:put, {field, value}}
  end

  #####
  # Internal Functions
  def do_process(pid, command, input) do
    opts = [
      out: {:send, pid},
      err: {:send, pid},
    ]
    
    unless is_nil(input),
    do: opts = [input: input] ++ opts

    Porcelain.spawn_shell(command, opts)
  end

  def determine_status(state) do
    cond do
      !(state.stderr) ->
        0
      "" == state.stderr ->
        0
      # status_raw is 0, but stderr neither empty, nor falsey
      state.status_raw == 0 ->
        1
      # set same as status_raw
      true ->
        state.status_raw
    end
  end

  #####
  # GenServer implementation

  def handle_call({:get_process, pid}, _from, state) do
    case Map.get(state, :process) do
      nil ->
        process = do_process(pid, state.command, state.input)
        #Logger.debug("process: #{inspect process}")
        Porcelain.Process.await(process, :infinity)
        new_state = Map.put(state, :process, process)
        {:reply, new_state, new_state}

      _ ->
        {:reply, state, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, field}, _from, state) do
    {:reply, Map.get(state, field), state}
  end

  def handle_call({:merge, items}, _from, state) do
    new_state = Map.merge(state, items)
    {:reply, new_state, new_state}
  end

  @doc "Handle the server stop message"
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:state, new_state}, _state) do
    {:noreply, new_state}
  end

  def handle_cast({:put, {field, fn_value}}, state) when is_function(fn_value) do
    {:noreply, Map.put(state, field, fn_value.(state))}
  end

  def handle_cast({:put, {field, value}}, state) do
    {:noreply, Map.put(state, field, value)}
  end

  def handle_info(_info={_pid, :data, :out, data}, state) do
    { :noreply, Map.put(state, :stdout_raw, "#{state.stdout_raw}\n#{data}") }
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    { :noreply, Map.put(state, :stderr_raw, "#{state.stderr_raw}\n#{data}") }
  end
 
  def handle_info(_info={_pid, :result, result=%Result{status: status}}, state) do
    { :noreply, Map.merge(state, %{status_raw: status, result: result}) }
  end

end

defmodule Krill.Debug do
  require Logger

  def run() do
    Logger.debug("Debugging..")
    Quaff.Debug.start()
    Quaff.Debug.load(Krill.Sample)
  end
end