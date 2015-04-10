defmodule Krill.Parser do
  @moduledoc """
  Deals with anything related to Porcelain.Process and Results
  """
  
  require Logger
  import Krill, only: [empty?: 1]

  @typedoc "Standard line"
  @type std_line :: {pos_integer, String.t}

  @typedoc "Rules can be a string, a regular expresion or a function that returns a boolean"
  @type rule :: String.t | Regex.t | (String.t -> as_boolean(term))

  @typedoc "Can be either a string or a regular expresion"
  @type pattern :: String.t | Regex.t


  @doc """
  Match `string` against and every rule in `rules`.
  Returns `true` if any of them matched, or `false` if none. 
  """
  @spec match_rule?(String.t, [rule]) :: boolean
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
  @spec match_rule?(String.t, rule) :: boolean
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
  @spec count_lines(String.t) :: non_neg_integer
  def count_lines(string),
    do: String.split(string, "\n") |> Enum.count


  @doc """
  Returns the number of lines in `string` for which `fun` returns a truthy value.
  """
  @spec count_lines(String.t, (String.t -> as_boolean(term))) :: non_neg_integer
  def count_lines(string, fun) when is_function(fun) do
    String.split(string, "\n")
    |> Enum.count(fun)
  end

  
  @doc """
  Returns the number of lines in `string` that match `pattern`.
  If `pattern` is a regular expression, `string` has to match to return true or 
  if `pattern` is a string, `pattern` has to be a substring of `string`
  """
  @spec count_lines(String.t, pattern) :: non_neg_integer
  def count_lines(string, pattern) do
    String.split(string, "\n") |> 
      Enum.count(&(&1 =~ pattern))
  end


  @doc """
  Rejects items in `collection` that are empty strings, `nil`  or
  `false`.
  """
  @spec reject_empty([std_line]) :: [std_line]
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
  strings or falsey values.

  It keeps the last item if it's a empty string, `nil` or `false`,
  to avoid triming a trailing new lines.

  Returns a string.
  """
  @spec join(Enumerable.t, String.t) :: String.t
  def join(collection, joiner \\ "\n") do
    collection
      |> reject_empty
      |> Enum.join(joiner)
  end

  @doc """
  Splits a `string` by `delimiters`. It strips the carriage return (\n)
  at the end of the string, if any.
  It retuns a `list`.
  """
  @spec split(String.t, String.t) :: list
  def split(string, delimiter \\ "\n") do
    string
      |> String.strip(?\n)
      |> String.split(delimiter)
  end


  @doc """
  Takes a `collection` which is a map with the format {line_no, line} and
  returns a map with the same format with the lines that matched `rules`.

  It also takes `string`, splits it into lines, and returns only the lines that
  match against `rules`".
  
  `rules` must be a list of rules consiting of `string`s or `regex`es.
  """
  @spec accept( nil | [std_line] | String.t, nil | [rule] ) :: nil | [std_line] | String.t

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
  Takes a `collection` which is a list with the format {line_no, line} and
  returns a map with the same format with the lines that did not match
  the `rules`.

  It also takes `string`, splits it into lines, and returns the lines that
  did not match against `rules`".
  
  `rules` must be a list of rules consiting of `string`s or `regex`es.
  """
  @spec reject( nil | [std_line] | String.t, nil | [rule] ) :: nil | [std_line] | String.t

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
  @spec numerify([String.t]) :: [std_line]
  def numerify(list) when is_list(list) do
    Enum.map_reduce(list, 1, fn(item, counter) -> { {counter, item}, counter+1} end) |> elem(0)
  end

  @doc """
  Takes a `list` with lines in the format [{line_no, line}, ...], and returns a list
  containing the lines only [line_1, line_2, ...]
  """
  @spec denumerify([std_line]) :: [String.t]
  def denumerify(list) when is_list(list)  do
    Enum.map(list, fn({_line_no, line}) -> line end)
  end
end