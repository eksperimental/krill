defmodule Krill.CLI do
  require Logger

  #use Application

  def start(_type, _args) do
    Krill.CLI.start_link
  end

  def main(args) do
    args |> parse_args |> do_process
  end

  defp parse_args(args) do
    {options, _argv, _errors} = OptionParser.parse(args, 
      switches: [n: :integer, url: :string]
    )
    Logger.info(options)
    Logger.info(_argv)
    Logger.info(_errors)
    case options do
      {[name: name], _, _} -> [name]
      {[name: true], _, _} -> :help
      _ -> :help
    end
  end

  defp do_process([name]) do
    IO.puts "Hello #{name}!"
  end

  defp do_process(:help) do
    IO.puts """
      Usage:
        ./krill --name [your name]

      Options:
        -- help     Show this help

      Description:
        Prints out an awesome message.
    """
  end

  #System.halt(0)
end