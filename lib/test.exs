defmodule Test do
  def prefilter_stdout(file, opts) do
    lines =  File.read!(file) |>
             String.split("\n")

    result = Enum.reject(lines, fn(line) ->
      Enum.find_value(opts[:reject], fn(regex) ->
        Regex.match?(regex, line)
      end)
    end)
    Enum.join(result, "\n")
  end

  def filter(opts) do
    IO.inspect opts
    #case opts do
    #  {:reject, list} when is_list(list) ->
    #    IO.puts "REJECT"
    #    inspect list
    #  [_, value]-> IO.puts " $$$$" <> inspect opts
    #end

    # Enum.reduce(kwlist, fn {<key>, <val>} -> <body1>; {<key>, <val>} -> <body2>; ... end)
    
    # Enum.reduce opts, fn
    #   (:reject, list) ->
    #     IO.puts "REJECT"
    #     inspect list
    #   (_, _) ->
    #     IO.puts " NO MATCH "
    #     nil
    # end

    # Enum.reduce opts, fn
    #   {:reject, list}, acc ->
    #     IO.puts "REJECT"
    #     inspect list
    #   {_, _}, acc->
    #     IO.puts " NO MATCH "
    #     nil
    # end
    
    # Enum.each opts, fn
    #   {:reject, list}, _acc ->
    #     IO.puts "REJECT"
    #     list
    #   {_, _}, _acc->
    #     IO.puts " NO MATCH "
    #     nil
    # end    

  end
end

reject = [
  ~r/Running \[.*\] checks on/,
  ~r/Checking \d+ external links\.\.\./,
  ~r/Ran on \d+ files!/,
  ~r/htmlproof [0-9.]+ \|/,
]

IO.puts Test.prefilter_stdout("../sample.log", [reject: reject])
#Test.filter([reject: reject, test: "BOO", ])