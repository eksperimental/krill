defmodule Krill.Htmlproof do
  use Krill

  def config do
    command_name = "htmlproof"  
    %{ 
      name: {:global, __MODULE__},
      command_name: command_name,
      #command: "htmlproof ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
      command: "htmlproof ~/git/eksperimental/krill/_site --file-ignore /docs/ --only-4xx --check-favicon --disable-external",
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
      message_ok: "OK: #{command_name} - Documents have been validated.",
      message_ok: "ERROR: #{command_name} - Documents did not validate.",
    }
  end

  def process_std(state) do
    #stdout
    stdout = Parser.accept(state[:stdout_raw], state[:accept][:stdout])
      |> Parser.reject(state[:stdout_raw], state[:reject][:stdout])

    #stderr
    stderr = Parser.accept(state[:stderr_raw], state[:accept][:stderr])
      |> Parser.reject(state[:stderr_raw], state[:reject][:stderr])
      |> discard_favicons_on_redirects
      |> discard_files_no_errors

    Map.merge(state, %{stdout: stdout, stderr: stderr})
  end

  def discard_favicons_on_redirects(text) do
    lines =  text |> String.split("\n")
    
    #Logger.debug "DEBUGGING: discard_favicons_on_redirects"
    {result, _} = Enum.map_reduce(lines, "", fn(line, current_file)->
      cond do
        Parser.match_rule?(~r/^- /, line) ->
          current_file = line

        true ->
          # ignore favicon on redirect pages
          if Parser.match_rule?("/getting_started/", current_file) and
             Parser.match_rule?(~r/\s+\*\s+no favicon specified/, line) do
            line = nil
          end       
      end
      {line, current_file}
    end)
    #Logger.debug "#{inspect result}"
    result |> Parser.join("\n")
  end

  # delete every file that has no errors
  # (ie, any file that is not followed by a line starting with "  *  ")
  def discard_files_no_errors(text) do
    Regex.replace(~r/\- .*\n(?!\s+\*\s+)/, text, "")
  end

  # Improve OK/ERRROR messages  
  defp capture(state) do
    #Logger.debug("STDOUT_RAW:: #{inspect(state[:stdout_raw])}")
    #Logger.debug("STDERR_RAW:: #{inspect(state[:stderr_raw])}")
    merge_state = %{}

    # Grab total number of documents and errors
    destructure( [_, total_files], Regex.run(~r/Ran on (\d+) files!/, state[:stdout_raw]) )
    destructure( [_, total_external_links], Regex.run(~r/Checking (\d+) external links/, state[:stdout_raw]) )

    total_errors = Parser.accept(state[:stderr_raw], [~r/^\s+\*\s+/]) |> Parser.count_lines
    error_files = Parser.accept(state[:stderr_raw], [~r/^-\s+/]) |> Parser.count_lines
    
    if total_files do
      message_ok = "OK: #{state[:command_name]} - #{total_files} documents have been validated."
      state = Map.put(state, :message_ok, message_ok)
    end

    if total_errors do
      message_error = "ERROR: #{state[:command_name]} - #{total_errors} errors found in #{error_files} documents."
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