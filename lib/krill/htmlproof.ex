defmodule Krill.Htmlproof do
  use Krill, name: {:global, __MODULE__}
  
  @command_name "htmlproof"
  @command      "htmlproof ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash"

  def new(pid) do
    Server.put(pid, :command, @command)

    # default messages
    Server.put(pid, :message_ok, "OK: #{@command_name} - Documents have been validated.")
    Server.put(pid, :message_ok, "ERROR: #{@command_name} - Documents did not validate.")

    Server.put(pid, :reject, [
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
      ],
    ])
    
    :ok
  end

  def process_std(pid) do
    #stdout
    stdout = Server.get(pid, :stdout_raw) |>
      Parser.accept(Server.get(pid, :accept)[:stdout]) |> 
      Parser.reject(Server.get(pid, :reject)[:stdout])
    Server.put(pid, :stdout, stdout)

    #stderr
    stderr = Server.get(pid, :stderr_raw) |>
      Parser.accept(Server.get(pid, :accept)[:stderr]) |> 
      Parser.reject(Server.get(pid, :reject)[:stderr]) |>
        discard_favicons_on_redirects |>
        discard_files_no_errors
    Server.put(pid, :stderr, stderr)

    :ok
  end

  defp discard_favicons_on_redirects(text) do
    lines =  text |> String.split("\n")
    
    lines = Enum.map_reduce(lines, nil, fn(line, current_file)->
      cond do
        line =~ ~r/^- / ->
          current_file = line
        true ->
          # ignore favicon on redirect pages
          if current_file =~ "/getting_started/" and lines =~ ~r/\s+\*\s+no favicon specified\n/ do
            line = nil
          end
      end
      line
    end)

    Enum.join(lines, "\n")
  end

  # delete every file that has no errors
  # (ie, any file that is not followed by a line starting with "  *  ")
  defp discard_files_no_errors(text) do
    regex = ~r/\- .*\n(?!\s+\*\s+)/
    Regex.replace(regex, text, "")
  end

  # Improve OK/ERRROR messages  
  defp capture(pid) do
    stdout_raw = Server.get(pid, :stdout_raw)
    stderr_raw = Server.get(pid, :stderr_raw)
    Logger.debug("STDOUT_RAW:: #{inspect(stdout_raw)}")
    Logger.debug("STDERR_RAW:: #{inspect(stderr_raw)}")

    # Grab total number of documents and errors
    destructure( [_, total_files], Regex.run(~r/Ran on (\d+) files!/, stdout_raw) )
    destructure( [_, total_external_links], Regex.run(~r/Checking (\d+) external links/, stdout_raw) )

    total_errors = Parser.accept(stderr_raw, [~r/^\s+\*\s+/]) |> Parser.count_lines
    error_files = Parser.accept(stderr_raw, [~r/^-\s+/]) |> Parser.count_lines
    
    if is_integer(total_files) do
      msg_ok = "OK: #{Server.get(pid, :command_name)} - #{total_files} documents have been validated."
      Server.put(pid, :message_ok, msg_ok)
    end

    if is_integer(total_errors) do
      msg_error = "ERROR: #{Server.get(pid, :command_name)} - #{total_errors} errors found in #{error_files} documents."
      # Show number of documents and links if available
      if is_integer(total_errors) do
        msg_error = msg_error <> " Total Documents: #{total_files}."
      end
      if is_integer(total_external_links) do
        msg_error = msg_error <> " Total Links: #{total_external_links}."
      end
      Server.put(pid, :message_error, msg_error)
    end

    :ok
  end
end