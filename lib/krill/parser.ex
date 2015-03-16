defmodule Krill.Parser do

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

  def accept(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.filter(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

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