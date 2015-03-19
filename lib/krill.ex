defmodule Krill do
  use Behaviour
  defcallback process_std(pid) :: any
  defcallback new(pid) :: any

  defmacro __using__(opts) do
    quote do
      require Logger
      import Krill
      alias Krill.Server
      alias Krill.Parser
      @behaviour Krill

    if unquote(opts[:name]) do
      @name unquote(opts[:name])
    end

      def new(pid), do: :ok
      def process_std(pid), do: :ok
      def capture(pid), do: nil

      def run(module \\ __MODULE__) do
        {:ok, pid} = Server.start_link(module, %Server.Command{})
        Logger.debug("PID: #{inspect(pid)}")
        :ok = new(pid)
        Server.get_process(pid)
        capture(pid)
        :ok = process_std(pid)
        Logger.debug("STATE: #{inspect(Server.state(pid))}")
        {:ok, pid}
      end

      def init(options) do
        {:ok, options}
      end

      def stop(pid) do
        Server.stop(pid)
      end

      defoverridable [new: 1, process_std: 1, capture: 1, run: 1, init: 1, stop: 1, ]
    end
  end
end

defmodule Krill.Server do
  require Logger
  use GenServer              
  alias Porcelain.Process
  alias Porcelain.Result

  defmodule Command do
    defstruct [
      command: nil, 
      input: nil,
      stdout: nil, stdout_raw: nil,
      stderr: nil, stderr_raw: nil,
      message_ok: "OK: Everything is alright.",
      message_error: "ERROR: Errors have been found.",
      accept: [stdout: nil, stderr: nil],
      reject: [stdout: nil, stderr: nil], 
      process: nil,
      response: nil,
    ]
  end

  #####
  # External API  

  def start_link(module, args) do
    GenServer.start_link(__MODULE__, args, name: {:global, module})
  end

  def get_process(pid) do
    GenServer.call pid, :get_process
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
  def state(pid, new_state) do
    GenServer.cast pid, {:state, new_state}
  end

  @doc "Get field"
  def get(pid, field) do
    GenServer.call pid, {:get, field}
  end

  @doc "Merge new_state into current_state"
  def merge(pid, new_state) do
    GenServer.call pid, {:merge, new_state}
  end

  @doc "Put field, value pair into state"
  def put(pid, field, value) do
    GenServer.cast pid, {:put, {field, value}}
  end

  #####
  # Internal Functions
  def do_process(command, input) do
    opts = [
      out: {:send, self()},
      err: {:send, self()},
    ]
    
    unless is_nil(input),
    do: opts = [input: input] ++ opts

    Logger.debug("Current Line: #{__ENV__.line}")
    process = Porcelain.spawn_shell(command, opts)
    Logger.debug("Current Line: #{__ENV__.line}")
    Logger.debug("PROCESS: #{inspect(process)}")
    #Process.await(process, :infinity)
    process
  end

  #####
  # GenServer implementation

  def handle_call(:get_process, _from, state) do
    if is_nil Map.get(state, :process) do
      process = do_process(state.command, state.input)
      Logger.debug("Current Line: #{__ENV__.line}")
      Process.await(process)
      Logger.debug("Current Line: #{__ENV__.line}")
      new_state = Map.put(state, :process, process)
      Logger.debug("NEW STATE: #{inspect(new_state)}")
      {:reply, new_state, new_state}
    else
      {:reply, state, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get, field}, _from, state) do
    {:reply, Map.get(state, field), state}
  end

  def handle_call({:merge, item}, _from, state) do
    new_state = Map.merge(state, item)
    {:reply, new_state, new_state}
  end

  @doc "Handle the server stop message"
  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:state, new_state}, _state) do
    {:noreply, new_state, new_state}
  end

  def handle_cast({:put, {field, value}}, state) do
    {:noreply, Map.put(state, field, value)}
  end

  # def handle_info(info={ :EXIT, _conn, _reason }, state) do
  #   IO.puts "FINISHED! INFO: #{inspect info}"
  #   { :noreply, state }
  # end

  def handle_info(_info={_pid, :data, :out, data}, state) do
    new_state = Map.put(state, :stdout_raw, data)
    state(self(), new_state)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    new_state = Map.put(state, :stderr_raw, data)
    state(self(), new_state)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :result, %Result{status: _status}}, state) do
    Logger.debug("status: #{_status}")
    {:noreply, state}
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