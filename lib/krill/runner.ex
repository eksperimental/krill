defmodule Krill.Runner do
  use GenServer                      

  #use Application
  alias Porcelain.Process
  alias Porcelain.Result

  use Behaviour
  defcallback process_std :: any
  defcallback new :: any
  #defcallback start :: :ok | {:error, term}

  defmodule Exec do
    defstruct [
      command: nil, 
      input: nil, output: nil,
      stdout: nil, stdout_raw: nil,
      stderr: nil, stderr_raw: nil,
      response: nil,
      message_ok: "OK: Everything is alright.",
      message_error: "ERROR: Errors have been found.",
    ]
  end

  #####
  # External API  

  def start_link(module) do
    GenServer.start_link(module, %Exec{}, name: {:global, module})
  end

  def get(pid, field) do
    GenServer.call pid, {:get, field}
  end

  def put(pid, field, value) do
    GenServer.cast pid, {:put, field}
  end

  def get_exec(pid) do
    GenServer.call pid, :get_exec
  end

  def run(module, command, input \\ nil) do
    {:ok, pid} = start_link(module)
    :ok = new
    messages_default(unquote(dict))
    get_exec(dict, command, input)
    capture
    process_std
  end

  #####
  # GenServer implementation

  def handle_call(:get_exec, _from, current) do
    if is_nil(current) or is_nil(current.output) do
      output = exec(command, input)
      updated = %{current | output: output}
      { :reply, updated, updated }      
    else
      { :reply, current.output, current }
    end
  end

  def handle_call({:get, field}, _from, current) do
    { :reply, current[field], current }
  end

  def handle_cast({:put, item}, current) do
    { :noreply, %{current | item} }
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

    %Process{pid: pid} = Porcelain.spawn_shell(command, opts)
    #handle_output(pid, dict)
  end

  #TODO
  def handle_info(info, state) do
    receive do
      {^pid, :data, :out, data} ->
        state = %{state | stdout_raw: data}
      {^pid, :data, :err, data} ->
        state = %{state | stderr_raw: data}
        handle_output(info, state)
      {^pid, :result, %Result{status: status}} ->
        IO.puts "status:\n#{status}"
        capture
        process_std
    #after
    #  5_000 -> IO.puts "timeout"
    end
  end


  ##################################################
  # def messages_default(pid) do
  #   put(pid, :message_ok, "OK: Everything is alright.")
  #   put(pid, :message_error, "ERROR: Errors have been found.")
  # end
end
