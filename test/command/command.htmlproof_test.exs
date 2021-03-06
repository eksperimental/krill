defmodule Command.HtmlproofTest do
  use ExUnit.Case, async: true
  require Logger
  alias Krill.Parser
  alias Command.Htmlproof
  doctest Command.Htmlproof

  test "discard_favicons_on_redirects" do
    text = """
- ./_site/getting_started/mix-otp/task-and-gen-tcp.html
  *  linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist (line 227)
  *  no favicon specified
- ./_site/getting_started/1.html
- ./_site/getting_started/mix_otp/5.html
  *  no favicon specified
- ./_site/test.html
  *  no favicon specified
  *  internal script toc.js does not exist (line 184)
- something else
"""

    expected = """
- ./_site/getting_started/mix-otp/task-and-gen-tcp.html
  *  linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist (line 227)
- ./_site/getting_started/1.html
- ./_site/getting_started/mix_otp/5.html
- ./_site/test.html
  *  no favicon specified
  *  internal script toc.js does not exist (line 184)
- something else
"""

    #Logger.debug inspect(text)
    #Logger.debug inspect(expected)

    lhs = text
      |> Parser.split
      |> Parser.numerify
      |> Htmlproof.discard_favicons_on_redirects
      |> Parser.denumerify
      |> Parser.join

    assert lhs == String.strip(expected)
  end


  test "discard_files_no_errors" do
    text = """
- ./_site/getting_started/mix-otp/task-and-gen-tcp.html
  *  linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist (line 227)
  *  no favicon specified
- ./_site/getting_started/1.html
- ./_site/getting_started/2.html
- ./_site/getting_started/3.html

- ./_site/getting_started/mix_otp/5.html
  *  no favicon specified
- ./_site/test.html
  *  no favicon specified
  *  internal script toc.js does not exist (line 184)
- something else
- something else2
"""

    expected = """
- ./_site/getting_started/mix-otp/task-and-gen-tcp.html
  *  linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist (line 227)
  *  no favicon specified
- ./_site/getting_started/mix_otp/5.html
  *  no favicon specified
- ./_site/test.html
  *  no favicon specified
  *  internal script toc.js does not exist (line 184)
"""
    lhs = text
      |> Parser.split
      |> Parser.numerify
      |> Htmlproof.discard_files_no_errors
      |> Parser.denumerify
      |> Parser.join
      
   assert lhs == String.strip(expected)
 end
end
