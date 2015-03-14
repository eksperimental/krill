defmodule Krill.Parse do
  def capture, do: nil
  def process_std, do: :ok

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