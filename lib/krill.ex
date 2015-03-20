defmodule Krill do
  use Behaviour
  defcallback process_std(pid) :: any
  defcallback new(pid) :: any

  defmacro __using__(_opts) do
    quote do
      use Application
      require Logger
      import Krill
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
        Logger.debug("PID [run]: #{inspect(pid)}")

        :ok = new(pid)
        state = Server.state(pid)
        Logger.debug "Running #{state.command_name}"
        Logger.debug "$ #{state.command}"

        Server.get_process(pid)
        capture(pid)
        :ok = process_std(pid)
        
        final_state = Server.state(pid)
        Logger.debug("FINAL STATE [run]: #{inspect(final_state)}")

        output(pid)
        Server.stop(pid)
        {:ok, pid, final_state}
      end

      def output(pid) do
        stdout = Server.get(pid, :stdout)
        stderr = Server.get(pid, :stderr)

        case stderr do
          nil ->
            Logger.debug("STDOUT")
            IO.puts stdout

          _ ->
            Logger.debug("STDOERR")
            IO.puts :stderr, stderr
            IO.puts stdout
        end
      end

      def debug do
        {:ok, pid}  = start_link()
        :ok = new(pid)
        Logger.debug("pid [debug]: #{inspect(pid)}")
        state = Server.state(pid)
        Logger.debug("state [debug]: #{inspect(state)}")
        Logger.debug("self() [debug]: #{inspect self}")

        process = Server.do_process(pid, state.command, state.input)
        Logger.debug("process: #{inspect(process)}")
        Porcelain.Process.await(process, :infinity)
        final_state = Server.state(pid)
        Logger.debug("FINAL STATE [run]: #{inspect(final_state)}")
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
      status: nil,
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

  def terminate(reason, state) do
    IO.puts "Process Terminated. Reason: #{inspect reason}"
    IO.puts "State: #{inspect(state)}"
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

  #####
  # GenServer implementation

  def handle_call({:get_process, pid}, _from, state) do
    Logger.debug "FROM: #{inspect _from}"
    case Map.get(state, :process) do
      nil ->
        process = do_process(pid, state.command, state.input)
        Logger.debug("process: #{inspect process}")
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

  def handle_cast({:put, {field, value}}, state) do
    {:noreply, Map.put(state, field, value)}
  end

  def handle_info(_info={_pid, :data, :out, data}, state) do
    new_state = Map.put(state, :stdout_raw, data)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    new_state = Map.put(state, :stderr_raw, data)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :result, result=%Result{status: status}}, state) do
    { :noreply, Map.merge(state, %{status: status, result: result})}
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