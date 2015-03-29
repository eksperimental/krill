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

  test "accept lines",  %{rules: rules, } do
    # collection = %{
    #   1 =>  "1 - One",
    #   2 =>  "",
    #   3 =>  "2 - Two: Ran on 909 files!",
    #   4 =>  "",
    #   5 =>  "3 - Three",
    # }
    
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
discart this line
- Two: Ran on 909 files!

3 - Three
"""

    result = [
      {1, "1 - One"},
      {2, "discart this line"},
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


  test "accept/reject lines with numerify/denumerify",  %{rules: rules, } do
    text = """
1 - One
discart this line
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
