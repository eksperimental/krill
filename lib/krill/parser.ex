defmodule Krill.Parser do
  import Krill.Macro
  require Logger

  @doc """
  Match `string` against and every rule in `rules`.
  Returns `true` if any of them matched, or `false` if none. 
  """
  def match_rule?(string, rules) when is_bitstring(string) and is_list(rules) do
    Enum.find_value(rules, false,
      fn(rule) -> match_rule?(string, rule)
    end)
  end


  @doc """
  Matches `rule` against `string`.

  Rule can be be a `function`, a `string` or `regular expession`.

  Returns `true` or `false`.
  """
  def match_rule?(string, rule) when is_bitstring(string) do
    cond do
      is_function(rule) ->
        rule.(string)
      
      empty?(string) and empty?(rule) and is_bitstring(rule) ->
        true

      empty?(string) or ( empty?(rule) and is_bitstring(rule) ) ->
        false

      true ->
        string =~ rule  #match regex or bitstring
    end
  end


  @doc """
  Returns the numer of lines in `string`.
  """
  def count_lines(string),
  do: String.split(string, "\n") |> Enum.count


  @doc """
  Returns the number of lines in `string` for which `fun` returns a truthy value.
  """
  def count_lines(string, fun) when is_function(fun) do
    String.split(string, "\n")
    |> Enum.count(string, fun)
  end

  
  @doc """
  Returns the number of lines in `string` that match `fun` returns a truthy value.
  """
  def count_lines(string, pattern) do
    String.split(string, "\n") |> 
      Enum.count(string, &(&1 =~ pattern))
  end


  @doc """
  Rejects items in `collection` that are empty strings, `nil`  or
  `false`.
  """
  def reject_empty(collection) when is_list(collection) do
    Enum.reject( collection, fn
      {_line_no, line} ->
        empty?(line)
      line ->
        empty?(line)
    end)

  end


  @doc """
  Joins a `collection` with `joiner`, removing items that are empty
  strings, `nil` or `false` values.

  It keeps the last item if it's a empty string, `nil` or `false`,
  to avoid triming a trailing new lines.
  """
  def join(collection, joiner \\ "\n") do
    collection
      |> reject_empty
      |> Enum.join(joiner)
  end

  def split(string, delimiter \\ "\n") do
    string
      |> String.strip(?\n)
      |> String.split(delimiter)
  end


  ####################

  @doc """
  Takes a `collection` which is a map with the format %{line_no, line} and
  returns a map with the same format with the lines that matched `rules`.

  It also takes `string`, splits it into lines, and returns only the lines that
  match against `rules`".
  
  `rules` must be a list of rules consiting of `string`s or `regex`es.
  """
  @spec accept( nil | list | String.t, nil | list ) :: map | String.t
  def accept(nil, _rules), do: nil

  def accept(items, nil) when is_list(items) or is_bitstring(items), do: items

  def accept(collection, rules) when is_list(collection) and is_list(rules) do
    Enum.filter( collection, fn({_line_no, line}) ->
      match_rule?(line, rules)
    end)
  end

  def accept(string, rules) when is_bitstring(string) and is_list(rules) do
    String.split(string, "\n")
    |> Enum.filter( fn(line) ->
        match_rule?(line, rules)
      end)
    |> join("\n")
  end


  @doc """
  Takes a `collection` which is a map with the format %{line_no, line} and
  returns a map with the same format with the lines that did not match
  the `rules`.

  It also takes `string`, splits it into lines, and returns the lines that
  did not match against `rules`".
  
  `rules` must be a list of rules consiting of `string`s or `regex`es.
  """

  @spec reject( nil | list | String.t, nil | list ) :: map | String.t
  def reject(nil, _rules), do: nil

  def reject(items, nil) when is_list(items) or is_bitstring(items), do: items

  def reject(collection, rules) when is_list(collection) and is_list(rules) do
    Enum.reject( collection, fn({_line_no, line}) ->
      match_rule?(line, rules)
    end)
  end

  def reject(string, rules) when is_bitstring(string) and is_list(rules) do
    String.split(string, "\n")
    |> Enum.reject( fn(line) ->
        match_rule?(line, rules)
      end)
    |> join("\n")
  end

  @doc """
  Takes a `list` with lines, and return a list with format [{line_no, line}, ...]
  """
  def numerify(list) when is_list(list) do
    Enum.map_reduce(list, 1, fn(item, counter) -> { {counter, item}, counter+1} end) |> elem(0)
  end

  @doc """
  Takes a `list` with lines in the format [{line_no, line}, ...], and return a list
  containing the lines only [line_1, line_2, ...]
  """
  def denumerify(list) when is_list(list)  do
    Enum.map(list, fn({_line_no, line}) -> line end)
  end
end