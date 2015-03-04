defmodule Htmlproof do
  #import Krill
  #use Application
  #@behaviour Krill
  use Krill

  @command_name "htmlproof"
  #@state {:global, __MODULE__}
  
  @moduledoc """
  """

  # #def start(_, _) do
  # def start do
  #   new
  #   state(:command, "htmlproof ./_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash")
  #   run
  # end

  @doc """
  Creates a new feeder
  """
  def new do
    state(:command, "htmlproof ./_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash")

    # default messages
    state(:message_ok, "OK: #{@command_name} - Documents have been validated.")
    state(:message_ok, "ERROR: #{@command_name} - Documents did not validate.")

    state(:reject, stdout: [
      ~r/Running \[.*\] checks on/,
      ~r/Checking \d+ external links\.\.\./,
      ~r/Ran on \d+ files!/,
      ~r/htmlproof [0-9.]+ \|/,
    ])

    state(:reject, stderr: [
      # Local errors, when /docs/ exists
      "linking to /docs/stable/elixir/Kernel.html#%7C%3E/2, but %7C%3E/2 does not exist",

      # Remote errors, when /docs/ doesn't exist
      ~r/internally linking to \/docs\/.*, which does not exist/,
      ~r/trying to find hash of \/docs\/.*, but .* does not exist/,
    ])
    
    :ok
  end

  # def run(command, input \\ nil) do
  #   exec(command, input)
  #   capture
  #   process_std
  # end

  defp process_std do
    #stdout
    stdout = read!(:stdout_raw) |> 
      accept(:stdout) |>
      reject(:stdout)
    state(:stdout, stdout)

    #stderr
    stderr = read!(:stderr_raw) |> 
      reject(:stderr) |>
      discard_favicons_on_redirects |>
      discard_files_no_errors
    state(:stderr_raw, stderr)

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
  defp capture do
    stdout_raw = read!(:stdout_raw) 
    stderr_raw = read!(:stderr_raw) 

    # Grab total number of documents and errors
    [_, total_files] = Regex.run(~r/Ran on (\d+) files!/, stdout_raw)
    [_, total_external_links] = Regex.run(~r/Checking (\d+) external links/, stdout_raw)
    total_errors = accept(stderr_raw, [~r/^\s+\*\s+/]) |> count_lines
    error_files = accept(stderr_raw, [~r/^-\s+/]) |> count_lines
    
    if is_integer(total_files) do
      msg_ok = "OK: #{state(:command_name)} - #{total_files} documents have been validated."
      state(:message_ok, msg_ok)
    end

    if is_integer(total_errors) do
      msg_error = "ERROR: #{state(:command_name)} - #{total_errors} errors found in #{error_files} documents."
      # Show number of documents and links if available
      if is_integer(total_errors) do
        msg_error = msg_error <> " Total Documents: #{total_files}."
      end
      if is_integer(total_external_links) do
        msg_error = msg_error <> " Total Links: #{total_external_links}."
      end
      state(:message_error, msg_error)
    end

    :ok
  end
end