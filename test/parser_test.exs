defmodule Krill.ParserTest do
  use ExUnit.Case, async: true
  alias Krill.Parser
  doctest Krill.Parser

  setup do
    text = File.read!("./test/fixtures/sample.log")
    rules = [
      accept: [
        ~r/\d+ /,
      ],

      reject: [
        ~r/$\s+^/,
        "",
        ~r/Ran on \d+ files!/,
      ],
    ]
    {:ok, text: text, rules: rules, }
  end

  test "match_rules?" do
    string = "abcd\ndefg\n1234\n5678\n"
    assert Parser.match_rule?(string, [~r/[a-z]{1,4}/])
    refute Parser.match_rule?(string, [~r/[a-z]{5,}/])
    assert Parser.match_rule?(string, [~r/[a-z]{5,}/, "8"])
    assert Parser.match_rule?(string, ["\n"])
    refute Parser.match_rule?(string, ["\n\n"])

    assert Parser.match_rule?("a", "a")
    refute Parser.match_rule?("A", "a")
    assert Parser.match_rule?("A", "A")
    assert Parser.match_rule?("a", ~r/a/)
    assert Parser.match_rule?("a", ~R/a/)
    refute Parser.match_rule?("A", ~r/a/)
    assert Parser.match_rule?("A", ~r/A/)
    assert Parser.match_rule?("a", ~r/a/i)
    assert Parser.match_rule?("A", ~r/a/i)

    #empty string should always return true
    assert Parser.match_rule?("", "")
    assert Parser.match_rule?("", ["foo", ""])

    #string is not empty, so it should return false    
    refute Parser.match_rule?(string, "")
    refute Parser.match_rule?(string, ["", "foo"])

    #empty string and not empty rule
    refute Parser.match_rule?("", "foo")
    refute Parser.match_rule?("", ["foo", "bar"])
    
    #functions
    assert Parser.match_rule?(string, fn(string)-> String.contains?(string, "bc") end )
    refute Parser.match_rule?(string, fn(string)-> String.contains?(string, "cb") end )
  end

  test "count lines", %{text: text} do
    assert Parser.count_lines(text) == 15
  end

  test "count lines" do
    text = "1\n2\n3\n4"
    assert Parser.count_lines(text) == 4
  end

  test "count lines trailing new line" do
    text = "1\n2\n3\n4\n"
    assert Parser.count_lines(text) == 5
  end

  test "count lines trailing stiped" do
    text = "1\n2\n3\n4\n"
    assert (text |> String.strip(?\n) |> Parser.count_lines) == 4
  end

  test "reject_empty" do
    assert Parser.reject_empty(["abcd", "", "space", " ", "1234"]) == ["abcd", "space", " ", "1234"]
    assert Parser.reject_empty(["", "abcd", "", "space", " ", "1234"]) == ["abcd", "space", " ", "1234"]
    assert Parser.reject_empty(["", "", "abcd", "", "space", " ", "1234"]) == ["abcd", "space", " ", "1234"]
    assert Parser.reject_empty(["", "", "abcd", "", "space", " ", "1234", ""]) == ["abcd", "space", " ", "1234"]
    assert Parser.reject_empty([""]) == []
    assert Parser.reject_empty(["", ""]) == []
    assert Parser.reject_empty(["", "a", ""]) == ["a"]
    assert Parser.reject_empty([]) == []
  end

  test "accept lines",  %{rules: rules, } do
    collection = [
      {1, "1 - One"},
      {2, ""},
      {3, "2 - Two: Ran on 909 files!"},
      {4, ""},
      {5, "3 - Three"},
    ]

    result = [
      {1, "1 - One"},
      {3, "2 - Two: Ran on 909 files!"},
      {5, "3 - Three"},
    ]

    assert Parser.accept(collection, rules[:accept]) == result
  end

  test "reject lines",  %{rules: rules, } do
    collection = [
      {1, "1 - One"},
      {2, ""},
      {3, "2 - Two: Ran on 909 files!"},
      {4, ""},
      {5, "3 - Three"},
    ]

    result = [
      {1, "1 - One"},
      {5, "3 - Three"},
    ]

    assert Parser.reject(collection, rules[:reject]) == result
  end


  test "accept/reject lines",  %{rules: rules, } do
    collection = [
      {1,  "1 - One"},
      {2,  "discart this line"},
      {10, "- Two: Ran on 909 files!"},
      {12, ""},
      {14, "3 - Three"},
    ]

    result = [
      {1,  "1 - One"},
      {14, "3 - Three"},
    ]

    filtered =  collection |>
      Parser.accept(rules[:accept]) |>
      Parser.reject(rules[:reject]) 

    assert filtered == result
  end


  test "numerify" do
    text = """
1 - One
discard this line
- Two: Ran on 909 files!

3 - Three
"""
    result = [
      {1, "1 - One"},
      {2, "discard this line"},
      {3, "- Two: Ran on 909 files!"},
      {4, ""},
      {5, "3 - Three"},
    ]

    filtered =  text
      |> String.strip(?\n)
      |> String.split("\n")
      |> Parser.numerify

    assert filtered == result
  end


  test "denumerify" do
    list = [
      {1, "1 - One"},
      {2, "discard this line"},
      {30, "- Two: Ran on 909 files!"},
      {4, ""},
      {5, "3 - Three"},
      {100, ""},
    ]
    
    result = [
      "1 - One",
      "discard this line",
      "- Two: Ran on 909 files!",
      "",
      "3 - Three",
      "",
    ]    

    assert Parser.denumerify(list) == result
  end

  test "accept/reject lines with numerify/denumerify",  %{rules: rules, } do
    text = """
1 - One
discard this line
- Two: Ran on 909 files!

3 - Three
"""

    result = """
1 - One
3 - Three
"""

    filtered =  text
      |> String.strip(?\n)
      |> String.split("\n")
      |> Parser.numerify
      |> Parser.accept(rules[:accept])
      |> Parser.reject(rules[:reject])
      |> Parser.denumerify
      |> Parser.join

    assert filtered == String.strip(result)
  end

end
