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

      def do_start do
        Server.start_link(__MODULE__, %Server.Command{})
      end

      def run do
        {:ok, pid} = do_start()
        Logger.debug("PID [run]: #{inspect(pid)}")

        :ok = new(pid)
        Server.get_process(pid)
        capture(pid)
        :ok = process_std(pid)
        
        Logger.debug("FINAL STATE [run]: #{inspect(Server.state(pid))}")
        {:ok, pid}
      end

      def debug do
        {:ok, pid}  = do_start()
        :ok = new(pid)
        Logger.debug("pid [debug]: #{inspect(pid)}")
        state = Server.state(pid)
        Logger.debug("state [debug]: #{inspect(state)}")
        Logger.debug("self() [debug]: #{inspect self}")

        process = Server.do_process(pid, state.command, state.input)
        Logger.debug("process: #{inspect(process)}")
        Porcelain.Process.await(process, :infinity)
        Logger.debug("FINAL STATE [debug]: #{inspect(Server.state(pid))}")
        {:ok, pid}
      end
        

      def init(options) do
        {:ok, options}
      end

      def stop(pid) do
        Server.stop(pid)
      end

      defoverridable [do_start: 0, new: 1, process_std: 1, capture: 1, run: 0, init: 1, stop: 1, ]
    end
  end
end

defmodule Krill.Server do
  require Logger
  use GenServer              
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
      result: nil,
      status: nil,
    ]
  end

  #####
  # External API  

  def start_link(module, args) do
    GenServer.start_link(__MODULE__, args, name: {:global, module})
  end

  def get_process(pid) do
    GenServer.call pid, {:get_process, pid}
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
    Logger.debug("pid (passed) [do_process]: #{inspect pid}")
    Logger.debug("self() [do_process]: #{inspect self}")

    opts = [
      out: {:send, pid},
      err: {:send, pid},
    ]
    
    unless is_nil(input),
    do: opts = [input: input] ++ opts

    Porcelain.spawn_shell(command, opts)
    #Porcelain.shell(command)
  end

  #####
  # GenServer implementation

  def handle_call({:get_process, pid}, _from, state) do
    Logger.debug("pid (passed) [handle_call]: #{inspect pid}")
    Logger.debug("self() [handle_call]: #{inspect self}")
    Logger.debug("from [handle_call]: #{inspect _from}")

    case Map.get(state, :process) do
      nil ->
        #opts = [
        #  out: {:send, self()},
        #  err: {:send, self()},
        #  input: state.input,
        #]
        #process = Porcelain.spawn_shell(state.command, opts)

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
    Logger.debug("MERGE new state: #{inspect new_state}")
    {:reply, new_state, new_state}
  end

  @doc "Handle the server stop message"
  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:state, new_state}, _state) do
    {:noreply, new_state}
  end

  def handle_cast({:put, {field, value}}, state) do
    Logger.debug("PUT field: #{inspect field}")
    Logger.debug("PUT value: #{inspect value}")
    Logger.debug("NEW_STATE: #{inspect Map.put(state, field, value)}")
    {:noreply, Map.put(state, field, value)}
  end

  # def handle_info(info={ :EXIT, _conn, _reason }, state) do
  #   IO.puts "FINISHED! INFO: #{inspect info}"
  #   { :noreply, state }
  # end

  def handle_info(_info={_pid, :data, :out, data}, state) do
    Logger.debug("OUT (#{inspect self}): #{inspect data}")
    new_state = Map.put(state, :stdout_raw, data)
    #state(self(), new_state)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    Logger.debug("ERR (#{inspect self}): #{inspect data}")
    new_state = Map.put(state, :stderr_raw, data)
    #state(self(), new_state)
    {:noreply, new_state}
  end
 
  def handle_info(_info={_pid, :result, result=%Result{status: status}}, state) do
    Logger.debug("RESULT (#{inspect self}): #{inspect result}")
    Logger.debug("info: #{inspect _info}")
    Logger.debug("status: #{inspect status}")
    Logger.debug("result: #{inspect result}")
    #put(self(), :status, status)
    #put(self(), :result, result)
    #new_state = state(self())
    new_state = Map.merge(state, %{status: status, result: result})
    Logger.debug("new_state: #{inspect new_state}")
    { :noreply, new_state}
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