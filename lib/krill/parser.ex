defmodule Krill.Parser do

  def match_rule?(rule, line) when is_bitstring(line) do
    cond do
      is_function(rule) ->
        rule.(line)
      
      (String.length(line) == 0) and is_bitstring(rule) and (String.length(rule) == 0) ->
        true

      (String.length(line) == 0) or ( is_bitstring(rule) and (String.length(rule)== 0) ) ->
        false

      true ->
        line =~ rule  #match regex or bitstring
    end
  end

  @doc "Count number of lines in a the string `text`"
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

  def accept(nil, _rules), do: nil
  def accept(text, nil) when is_bitstring(text), do: text
  def accept(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.filter(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> Enum.join("\n")
  end

  def reject(nil, _rules), do: nil
  def reject(text, nil) when is_bitstring(text), do: text
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