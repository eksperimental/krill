defmodule Krill do
  @moduledoc """
  """

  #use Application
  use Behaviour
  defcallback process_std :: any
  defcallback new :: any
  #defcallback start :: :ok | {:error, term}

  alias Porcelain.Process
  alias Porcelain.Result

  defmacro __using__(_opts) do
    quote do
      import Krill
      use Application
      @behaviour Krill
      @state {:global, unquote(__MODULE__)}
      defoverridable [capture: 0]
      #defoverridable [start:0, start: 2, run: 2, new: 0, capture: 0]

      def start(_, _) do
        start_link(@state)
        counter(1)
        start
        messages_default
      end

      def start do
        :ok = new
        run(state(:command))
      end

      def new, do: :ok

      def run(command, input \\ nil) do
        exec(command, input)
        capture
        process_std
      end
    end      
  end


  def capture, do: nil
  #def new, do: nil


  # AGENT
  def start_link(dict),
  do: Agent.start_link(fn -> HashDict.new end, name: dict)

  def state(id),
  do: Agent.get(@state, &Dict.get(&1, id))

  def state(id, message),
  do: Agent.update(@state, &Dict.put(&1, id, message))

  # COUNTER
  # get
  defp counter, do: state(:counter)
  # update
  defp counter(n), do: state(:counter, n)
  def counter_increase do
    result = counter + 1
    :ok = state(:counter, result)
    result
  end

  def timestamp_microseconds do
    {mega, sec, micro} = :os.timestamp
    ((mega * 1000000 + sec) * 1000000)+micro
  end

  defp messages_default do
    state(:message_ok, "OK: Everything is alright.")
    state(:message_error, "ERROR: Errors have been found.")
  end

  def read!(source) do
    case source do
      std when std in [:stdin, :stdout, :stderr, :stdin_raw, :stdout_raw, :stderr_raw, ] ->
        state(std)
      
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

  def accept(text, type) when is_atom(type),
  do: accept(text, state(type, :accept))

  def accept(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.filter(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

  def reject(text, type) when is_atom(type),
  do: reject(text, state(type, :reject))

  def reject(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.reject(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

  # PORCELAIN
  def exec(command, input \\ nil) do
    opts = [
      out: {:send, self()},
      err: {:send, self()}
    ]
    
    unless is_nil? input,
    do: opts = [input: input] ++ opts

    %Process{pid: pid} = Porcelain.spawn_shell(command, opts)
    handle_output(pid)
  end

  def handle_output(pid) do
    receive do
      {^pid, :data, :out, data} ->
        state(:stdout_raw, data)
        handle_output(pid)
      {^pid, :data, :err, data} ->
        state(:stderr_raw, data)
        handle_output(pid)
      {^pid, :result, %Result{status: status}} ->
        IO.puts "status:\n#{status}"
    after
      5_000 -> IO.puts "timeout"
    end
  end

end