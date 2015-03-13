defmodule PorcelainExample do
  @state {:global, __MODULE__}
  use Application

  def start_link,
  do: Agent.start_link(fn -> HashDict.new end, name: @state)

  def state(id),
  do: Agent.get(@state, &Dict.get(&1, id))

  def state(id, message),
  do: Agent.update(@state, &Dict.put(&1, id, message))


  # get
  defp counter, do: state(:counter)
  # update
  defp counter(n), do: state(:counter, n)
  def counter_increase do
    result = counter + 1
    :ok = state(:counter, result)
    result
  end

  def start(_, _) do
    start_link
    counter(1)

    input = "b\nd\nf\na\nc\n"
    IO.write """
    Launching external program:
      sort
    Input:
    #{input}
    Output:
    """

    instream = input |> String.split("\n") |> Stream.map(&(&1)<>"\n")
    #opts = [in: instream, out: :stream, err: :stream]
    opts = [in: instream, out: :stream]
    #process = %Porcelain.Process{out: outstream, err: errstream} = launch(opts)
    process = %Porcelain.Process{out: outstream} = launch(opts)
    #stdout = Enum.into(outstream, IO.stream(:stdio, :line), fn(x) -> #{counter_increase} <> #{x} end)
    stderr = Enum.into(outstream, IO.stream(:stdio, :line))
    #stderr = Enum.into(errstream, IO.stream(:stdio, :line))
    {:ok, self()}
  end

  defp launch(opts) do
    #Porcelain.spawn("sort", [], opts)
    Porcelain.spawn("perl", ["-pe", "s/^/#{counter_increase}|/"], opts)
  end

end
