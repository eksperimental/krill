defmodule Krill.Main do
  use Behaviour
  defcallback process_std :: any
  defcallback new :: any

  defmacro __using__(opts) do
    dict = Keyword.get(opts, :dict)

    quote do
      import Krill.Main
      # use Application
      @behaviour Krill.Main

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

  # AGENT
  def start_link(dict),
  do: Agent.start_link(fn -> HashDict.new end, name: dict)

  def state(dict, id),
  do: Agent.get(dict, &Dict.get(&1, id))

  def state(dict, id, message),
  do: Agent.update(dict, &Dict.put(&1, id, message))

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

end