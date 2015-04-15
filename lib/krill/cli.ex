defmodule Krill.CLI do
  @moduledoc """
  Executes the commands provided in list `commands`.

  If list is empty, then modules in the `config/config.exs` file are loaded.
  One or more commands If `krill command_one command_two`.
  
  If `krill :all` is called, then `.ex` files under `lib/command/`
  are used as commands (based on their file names).

  `commands` should be a list containing only strings.
  Returns :ok

  ### Usage  
  # help
  ./krill

  # execute all tasks in config
  ./krill :config

  #execute all tasks under lib/command/*.ex
  ./krill :all

  # execute one command
  ./krill sample
  ./krill sample htmlproof

  ./krill htmlproof
  ./krill htmlproof --execute "htmlproof custom command" --timeout=-1

  """

  require Logger

  @switches [help: :boolean, version: :boolean, execute: :string, timeout: :integer]
  @aliases [h: :help, v: :version, e: :execute, t: :timeout]

  def main(args) do
    args |> process
    #exit {:shutdown, 1}
  end

  def help do
    IO.puts """
      Usage:
      ./krill [--help | --version]
      ./krill [:config | :all | COMMAND_NAMES...] [--execute COMMAND_LINE] [--timeout TIMEOUT]

      ./krill --help
      ./krill --version

      ./krill :config
      ./krill :all

      ./krill FILTER
      ./krill FILTER_1 FILTER_2
      
      ./krill FILTER --execute COMMAND

      # Multiple commands not implemented yet
      #./krill FILTER_1 --execute COMMAND_1  FILTER_2 --execute COMMAND_2

      Options:
      -e, --execute       Execute command
      -t, --timeout       Timeout in milliseconds
      -v, --version       Show app version
      -h, --help          Show this help

      Description:
      Filter feeder for commands
    """
  end

  defp process(args) do
    {opts, rest, _errors} = OptionParser.parse(args,
                              [aliases: @aliases, switches: @switches])

    #Logger.debug(inspect args)
    #Logger.debug(inspect {opts, rest, _errors})

    # These options are generic for all the commands
    conf = %{}
    # determine timeout
    if Keyword.has_key?(opts, :timeout) do
      timeout = Keyword.fetch!(opts, :timeout)
      if timeout < 0, do: timeout = :infinity
      conf = Map.merge(conf, %{timeout: timeout})
    end

    cond do
      {:ok, true} == Keyword.fetch(opts, :help) ->
        help

      {:ok, true} == Keyword.fetch(opts, :version) ->
        version

      Enum.member?(rest, ":config") ->
        Krill.execute([":config"], conf)

      Enum.member?(rest, ":all") ->
        Krill.execute([":all"], conf)

      Keyword.has_key?(opts, :execute) ->
        conf = Map.merge(conf, %{command: Keyword.fetch!(opts, :execute)})
        Krill.execute([{hd(rest), conf}])

      # TODO: allow multiple commands
      length(rest) == 1 ->
        Enum.map(rest, &{&1, conf})
        |> Krill.execute

      true ->
        # TODO: show error message before help
        help
    end
  end

  def version do
    IO.puts  "#{Krill.app} version #{Krill.version}"
  end

end