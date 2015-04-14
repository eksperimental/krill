defmodule Krill.CLI do
  require Logger

  @aliases [h: :help, v: :version, e: :execute]
  @switches [h: :boolean, version: :boolean, e: :string]
  

  def main(args) do
    args |> process
  end

  defp process(args) do
    {opts, rest, _errors} = OptionParser.parse(args,
                              [aliases: @aliases, switches: @switches])

    Logger.debug(inspect args)
    Logger.debug(inspect {opts, rest, _errors})

    cond do
      {:ok, true} == Dict.fetch(opts, :help) ->
        help

      {:ok, true} == Dict.fetch(opts, :version) ->
        version

      true ->        
        case rest do
          [:config] ->
            execute([":config"])
          
          [:all] ->
            execute([":all"])
          
          _ ->
            case opts do
              [execute: command_line] ->
                Krill.execute([{hd(rest), command_line}])

              _ ->
                Krill.execute(rest)
            end
        end
    end
  end

  def help do
    IO.puts """
      Usage:
      ./krill --help
      ./krill --version

      ./krill :config
      ./krill :all

      ./krill FILTER
      ./krill FILTER_1 FILTER_2
      
      ./krill FILTER --execute COMMAND

      #./krill FILTER_1 --execute COMMAND_1  FILTER_2 --execute COMMAND_2

      Options:
      -f, --filter        Filter to be used
      -e, --execute       Execute command
      -v, --version       Show app version
      -h, --help          Show this help

      Description:
      Filter feeder for commands
    """
    exit {:shutdown, 1}
  end

  def version do
    IO.puts  "#{Krill.app} version #{Krill.version}"
    exit {:shutdown, 1}
  end


  @doc """
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
  ./krill htmlproof --execute htmlproof custom command

  """
  @spec execute([String.t | {String.t | String.t}]) :: :ok | :error
  def execute(command_names) when is_list(command_names) do
    Krill.execute(command_names)
  end

end