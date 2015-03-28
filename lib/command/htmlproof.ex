defmodule Command.Htmlproof do
  use Krill

  def config do
    command_name = "htmlproof"  
    %{ 
      name: {:global, __MODULE__},
      command_name: command_name,
      #command: "htmlproof ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
      command: "htmlproof ./test/fixtures/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --disable-external",
      reject: [
        stdout: [
          ~r/Running \[.*\] checks on/,
          ~r/Checking \d+ external links\.\.\./,
          ~r/Ran on \d+ files!/,
          ~r/htmlproof [0-9.]+ \|/,
        ],
        stderr: [
          # Local errors, when /docs/ exists
          "linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist",

          # Remote errors, when /docs/ doesn't exist
          ~r/internally linking to \/docs\/.*, which does not exist/,
          ~r/trying to find hash of \/docs\/.*, but .* does not exist/,
        ]
      ],
      message_ok: "OK: #{command_name} - Everything is alright.",
      message_error: "ERROR: #{command_name} - Documents did not validate.",
    }
  end

  def process_std(state) do
    #stdout
    stdout = state.stdout_raw
      |> Parser.accept(state.accept[:stdout])
      |> Parser.reject(state.reject[:stdout])
      |> Parser.reject_empty

    #stderr
    stderr = state.stderr_raw
      |> Parser.accept(state.accept[:stderr])
      |> Parser.reject(state.reject[:stderr])
      |> discard_favicons_on_redirects
      |> discard_files_no_errors
      |> Parser.reject_empty

    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end

  def discard_favicons_on_redirects(collection) do
    {result, _} = Enum.map_reduce(collection, "", fn({line_no, line}, current_file)->
      cond do
        Parser.match_rule?(line, ~r/^- /) ->
          current_file = line

        true ->
          # ignore favicon on redirect pages
          if Parser.match_rule?(current_file, "/getting_started/") and
             Parser.match_rule?(line, ~r/\s+\*\s+no favicon specified/) do
            line = nil
          end       
      end
      {{line_no, line}, current_file}
    end)
    #Logger.debug "#{inspect result}"
    result
  end

  # delete every file that has no errors
  # (ie, any file that is not followed by a line starting with "  *  ")
  def discard_files_no_errors(collection) do
    # add extra file element, so it can check if the last file needs to be removed.
    {result, {last_match, last_line_no, reject_lines}} = 
      Enum.map_reduce(collection, {nil, nil, []}, fn({line_no, line}, {last_match, last_line_no, reject_lines})->
      cond do
        Parser.match_rule?(line, ~r/^- /) ->
          if last_match == :file do
            reject_lines = [last_line_no] ++ reject_lines
          end
          last_match = :file

        Parser.match_rule?(line, ~r/^\s+\*\s+/) ->
          last_match = :error

        true ->
          nil
      end
      { {line_no, line}, {last_match, line_no, reject_lines} }
    end)

    # check if last_match was a :file, if so, add line_no to reject_lines
    if last_match == :file do
      reject_lines = [last_line_no] ++ reject_lines
    end
    
    #Logger.debug "REJECT LINES: #{inspect reject_lines}"
    #Logger.debug "RESULT: #{inspect(result)}"
    Enum.reject(result, fn({line_no, _line})-> Enum.member?(reject_lines, line_no) end  )
  end

  # Improve OK/ERRROR messages  
  def capture(state) do
    stdout = Keyword.values(state.stdout_raw) |> Parser.join
    stderr = Keyword.values(state.stderr_raw) |> Parser.join

    # Grab total number of documents and errors
    destructure( [_, total_files], Regex.run(~r/Ran on (\d+) files!/, stdout ) )
    destructure( [_, total_external_links], Regex.run(~r/Checking (\d+) external links/, stdout ) )

    total_errors = Parser.accept(stderr, [~r/^\s+\*\s+/]) |> Parser.count_lines
    error_files = Parser.accept(stderr, [~r/^-\s+/]) |> Parser.count_lines
    
    if total_files do
      message_ok = "OK: #{state.command_name} - #{total_files} documents have been validated."
      state = Map.put(state, :message_ok, message_ok)
    end

    if total_errors do
      message_error = "ERROR: #{state.command_name} - #{total_errors} errors found in #{error_files} documents."
      # Show number of documents and links if available
      if total_errors do
        message_error = message_error <> " Total Documents: #{total_files}."
      end
      if total_external_links do
        message_error = message_error <> " Total Links: #{total_external_links}."
      end
      state = Map.put(state, :message_error, message_error)
    end

    state
  end
end