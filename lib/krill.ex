defmodule Krill do
  use Behaviour
  defcallback process_std(pid) :: any
  defcallback new(pid) :: any

  defmacro __using__(opts) do
    quote do
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
        {:ok, pid} = Server.start_link(module, %Server.Exec{})
        IO.puts inspect(pid)
        :ok = new(pid)
        %{stdout: stdout, stderr: stderr} = Server.get_exec(pid)
        capture(pid)
        :ok = process_std(pid)
        {:ok, pid}
      end

      def init(options) do
        IO.puts inspect(options)
        {:ok, options}
      end

      defoverridable [new: 1, process_std: 1, capture: 1, run: 1, ]
    end
  end
end

defmodule Krill.Server do
  use GenServer                

  defmodule Exec do
    defstruct [
      command: nil, 
      input: nil, output: nil,
      accept: [stdout: nil, stderr: nil],
      reject: [stdout: nil, stderr: nil], 
      stdout: nil, stdout_raw: nil,
      stderr: nil, stderr_raw: nil,
      response: nil,
      message_ok: "OK: Everything is alright.",
      message_error: "ERROR: Errors have been found.",
    ]
  end

  #use Application
  alias Porcelain.Process
  alias Porcelain.Result

  #####
  # External API  

  def start_link(module, args) do
    GenServer.start_link(__MODULE__, args, name: {:global, module})
  end

  def get(pid, field) do
    GenServer.call pid, {:get, field}
  end

  def update(pid, item) do
    GenServer.cast pid, {:update, item}
  end

  def put(pid, field, value) do
    GenServer.cast pid, {:put, {field, value}}
  end

  def state(pid) do
    GenServer.call pid, :state
  end

  def state(pid, new_state) do
    GenServer.call pid, {:state, new_state}
  end

  def get_exec(pid) do
    GenServer.call pid, :get_exec
  end

  #####
  # GenServer implementation

  def handle_call(:get_exec, _from, state) do
    if is_nil(state) or is_nil(state.output) do
      IO.puts state.command
      IO.puts state.input
      output = exec(state.command, state.input)
      updated = %{state | output: output}
      { :reply, updated, updated }      
    else
      { :reply, state, state }
    end
  end

  def handle_call({:get, field}, _from, state) do
    { :reply, Map.get(state, field), state }
  end

  def handle_call({:update, item}, _from, state) do
    result = Map.merge(state, item)
    { :reply, result, result }
  end

  def handle_call(:state, _from, state) do
    { :reply, state, state }
  end

  def handle_call({:state, new_state}, _from, _state) do
    { :reply, new_state, new_state }
  end

  def handle_cast({:put, {field, value}}, state) do
    { :noreply, Map.put(state, field, value) }
  end

  ###################
  # PORCELAIN
  def exec(command, input \\ nil) do
    opts = [
      out: {:send, self()},
      err: {:send, self()}
    ]
    
    unless is_nil(input),
    do: opts = [input: input] ++ opts

    %Process{pid: _pid} = Porcelain.spawn_shell(command, opts)
    #handle_output(pid, dict)
  end

  #TODO
  def handle_info(_info={_pid, :data, :out, data}, state) do
    new_state = %{state | stdout_raw: data}
    IO.puts "out:" <> inspect(new_state)
    IO.puts "pid:" <> inspect(self())
    state(self(), new_state)
    IO.puts "state:" <> inspect( state(self) )
    #handle_info(_info, new_state)
  end
 
  def handle_info(_info={_pid, :data, :err, data}, state) do
    new_state = %{state | stderr_raw: data}
    IO.puts "err:" <> inspect(new_state)
    state(self(), new_state)
    #handle_info(_info, new_state)
  end
 
  def handle_info(_info={_pid, :result, %Result{status: status}}, state) do
    IO.puts "status: #{status}"
    #capture
    #process_std
    { :noreply, state }
  end

end