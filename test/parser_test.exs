defmodule Krill.ParserTest do
  use ExUnit.Case, async: true
  alias Krill.Parser
  doctest Krill.Parser

  setup do
    text = File.read!("./sample.log")

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

  test "accept lines",  %{rules: rules, } do
    text = """
1 - One

2 - Two: Ran on 909 files!

3 - Three
"""

    result = "1 - One
2 - Two: Ran on 909 files!
3 - Three"
    assert Parser.accept(text, rules[:accept]) == result
  end

  test "reject lines",  %{rules: rules, } do
    text = """
1 - One

2 - Two: Ran on 909 files!

3 - Three
"""

    result = "1 - One
3 - Three"
    assert Parser.reject(text, rules[:reject]) == result
  end


  test "accept/reject lines",  %{rules: rules, } do
    text = """
1 - One
discart this line
2 - Two: Ran on 909 files!

3 - Three
"""

    result = "1 - One\n3 - Three"

    filtered =  text |>
      Parser.accept(rules[:accept]) |>
      Parser.reject(rules[:reject]) 

    assert filtered == result
  end

end
