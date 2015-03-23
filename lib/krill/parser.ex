defmodule Krill.Parser do
  import Krill.Macro

  @doc """
  Matches `rule` against `line`.

  Rule can be be a `function`, a `string` or `regular expession`.

  Returns `true` or `false`.
  """
  def match_rule?(rule, line) when is_bitstring(line) do
    cond do
      is_function(rule) ->
        rule.(line)
      
      empty?(line) and empty?(rule) and is_bitstring(rule) ->
        true

      empty?(line) or ( empty?(rule) and is_bitstring(rule) ) ->
        false

      true ->
        line =~ rule  #match regex or bitstring
    end
  end

  @doc """
  Returns the numer of lines in `text`.
  """
  def count_lines(text),
  do: String.split(text, "\n") |> Enum.count(lines)

  @doc """
  Returns the number of lines in `text` for which `fun` returns a truthy value.
  """
  def count_lines(text, fun) when is_function(fun) do
    String.split(text, "\n")
    |> Enum.count(text, fun)
  end
  
  @doc """
  Returns the number of lines in `text` that match `fun` returns a truthy value.
  """
  defp count_lines(text, pattern) do
    String.split(text, "\n") |> 
      Enum.count(text, fn(line) -> lines =~ pattern end)
  end

  @doc """
  Splits `text` into lines, and accepts only the lines that match against `rules`".
  `rules` must be a list. Its rules can be strings or  regular expressions.
  """
  def accept(nil, _rules), do: nil
  def accept(text, nil) when is_bitstring(text), do: text
  def accept(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.filter(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> reject_empty |> Enum.join("\n")
  end


  @doc """
  Splits `text` into lines, and rejects the lines that match against
  `rules`".
  `rules` must be a list. Its rules can be strings or  regular
  expressions.
  """
  def reject(nil, _rules), do: nil
  def reject(text, nil) when is_bitstring(text), do: text
  def reject(text, rules) when is_bitstring(text) and is_list(rules) do
    String.split(text, "\n")
      |> Enum.reject(fn(line) ->
          Enum.find_value( rules, fn(rule) ->
            match_rule?(rule, line)
          end)
        end)
      |> reject_empty |> Enum.join("\n")
  end

  @doc """
  Rejects items in `collection` that are empty strings, `nil`  or
  `false`.
  """
  def reject_empty(collection) do
    Enum.reject( collection, &( empty?(&1) ) )
  end

  @doc """
  Joins a `collection` with `joiner`, removing items that are empty
  strings, `nil` or `false` values.

  It keeps the last item if it's a empty string, `nil` or `false`,
  to avoid triming a trailing new lines.
  """
  def join(collection, joiner \\ "") do
    collection
    |> reject_empty
    |> Enum.join(joiner)
  end

end