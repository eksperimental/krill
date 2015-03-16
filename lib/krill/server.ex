defmodule Krill.Server do
  use GenServer                      

  #use Application
  alias Porcelain.Process
  alias Porcelain.Result

  use Behaviour
  defcallback process_std :: any
  defcallback new :: any
  #defcallback start :: :ok | {:error, term}


  defmodule Exec do
    defstruct command: nil, 
      input: nil, output: nil,
      stdout: nil, stdout_raw: nil,
      stderr: nil, stderr_raw: nil,
      response: nil
  end

  #####
  # External API  

  def start_link(module) do
    GenServer.start_link(module, current_number, name: __MODULE__)
  end

  def get_exec(pid) do
    GenServer.call pid, :get_exec
  end

  # def save_value(pid, value) do
  #   GenServer.cast pid, {:save_value, value}
  # end

  # def get_value(pid) do
  #   GenServer.call pid, :get_value
  # end


  # def save_exec(value) do
  #   GenServer.cast __MODULE__, {:save_exec, value}
  # end


  #####
  # GenServer implementation

  # def handle_cast({:save_value, value}, _current_value) do
  #   { :noreply, value}
  # end

  # def handle_call(:get_value, _from, current_value) do 
  #   { :reply, current_value, current_value }
  # end

  def handle_call(:get_exec, _from, current) do
    if is_nil(current) or is_nil(current.output) do
      output = exec(command, input)
      updated = %{current | output: output}
      { :reply, updated, updated }      
    else
      { :reply, current.output, current }
    end
  end

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

  defmacro __using__(opts) do
    dict = Keyword.get(opts, :dict)

    quote do
      import Krill
      # use Application
      @behaviour Krill

      # def start(_type, _args) do
      #   {:ok, _pid} = Krill.Supervisor.start_link(unquote(__MODULE__), unquote(dict))
      # end

      def start(dict) do
        :ok = new
        run(dict, state(dict, :command))
      end

      # def start(_, _) do
      #   start_link(unquote(dict))
      #   counter(unquote(dict), 1)
      #   start(unquote(dict))
      #   messages_default(unquote(dict))
      # end

      def new, do: :ok
      #def capture, do: nil

      def run(dict, command, input \\ nil) do
        exec(dict, command, input)
        IO.puts "command: " <> state(@state, :command)
        IO.puts "stdout: " <> state(@state, :stdout_raw)
        #exit :kill

        # capture
        # process_std
      end

      #defoverridable [start: 1, start: 2, new: 0, run: 2, capture: 0, ]
      defoverridable [start: 1, start: 2, new: 0, run: 2, ]
    end
  end

  def capture, do: nil
  def process_std, do: :ok

  # def start(_, _), do: :ok

  # AGENT
  def start_link(dict),
  do: Agent.start_link(fn -> HashDict.new end, name: dict)

  def state(dict, id),
  do: Agent.get(dict, &Dict.get(&1, id))

  def state(dict, id, message),
  do: Agent.update(dict, &Dict.put(&1, id, message))

  # COUNTER
  # get
  def counter(dict), do: state(dict, :counter)
  # update
  def counter(dict, n), do: state(dict, :counter, n)
  def counter_increase(dict) do
    result = counter(dict) + 1
    :ok = state(dict, :counter, result)
    result
  end

  def timestamp_microseconds do
    {mega, sec, micro} = :os.timestamp
    ((mega * 1000000 + sec) * 1000000)+micro
  end

  def messages_default(dict) do
    state(dict, :message_ok, "OK: Everything is alright.")
    state(dict, :message_error, "ERROR: Errors have been found.")
  end

  def read!(dict, source) do
    case source do
      std when std in [:stdin, :stdout, :stderr, :stdin_raw, :stdout_raw, :stderr_raw, ] ->
        state(dict, std)
      
      path when is_bitstring(path) ->
        File.read!(path)
    end
  end

  def match_rule?(rule, line) do
    cond do
      is_function(rule) ->
        rule.(line)
      true ->
        line =~ rule  #match regex or bitstring
    end
  end

  def count_lines(text) do
    String.split(text, "\n") |> 
      Enum.count
  end

  defp count_lines(text, function) when is_function(function) do
    String.split(text, "\n") |> 
      Enum.count(text, function )
  end

  defp count_lines(text, pattern) do
    String.split(text, "\n") |> 
      Enum.count(text, fn(line) -> lines =~ pattern end)
  end

  def accept(dict, text, type) when is_atom(type),
  do: accept(text, state(dict, type, :accept))

  def accept(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.filter(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

  def reject(dict, text, type) when is_atom(type),
  do: reject(text, state(dict, type, :reject))

  def reject(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.reject(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

end
