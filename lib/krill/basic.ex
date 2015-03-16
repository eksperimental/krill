defmodule Krill.Basic do
  @state {:global, __MODULE__}
  use Krill, dict: @state

  @command_name "basic command"

  @moduledoc """
  """

  @doc """
  Creates a new feeder
  """
  def new do
    state(@state, :command, "echo 'foo bar'")

    state(@state, :reject, stdout: [
      "foobar",
    ])

    state(@state, :reject, stderr: [
      "foobar",
    ])
    
    :ok
  end

  def process_std do
    #stdout
    stdout = read!(@state, :stdout_raw) |> 
      accept(@state, :stdout) |>
      reject(@state, :stdout)
    state(@state, :stdout, stdout)

    #stderr
    stderr = read!(@state, :stderr_raw) |> 
      reject(@state, :stderr) |>
      discard_favicons_on_redirects |>
      discard_files_no_errors
    state(@state, :stderr_raw, stderr)

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
    stdout_raw = read!(@state, :stdout_raw) 
    stderr_raw = read!(@state, :stderr_raw) 

    IO.puts "STDOUT_RAW" <> stdout_raw
    #exit :kill
    # Grab total number of documents and errors
    [_, total_files] = Regex.run(~r/Ran on (\d+) files!/, stdout_raw)
    [_, total_external_links] = Regex.run(~r/Checking (\d+) external links/, stdout_raw)
    total_errors = accept(stderr_raw, [~r/^\s+\*\s+/]) |> count_lines
    error_files = accept(stderr_raw, [~r/^-\s+/]) |> count_lines
    
    if is_integer(total_files) do
      msg_ok = "OK: #{state(@state, :command_name)} - #{total_files} documents have been validated."
      state(@state, :message_ok, msg_ok)
    end

    if is_integer(total_errors) do
      msg_error = "ERROR: #{state(@state, :command_name)} - #{total_errors} errors found in #{error_files} documents."
      # Show number of documents and links if available
      if is_integer(total_errors) do
        msg_error = msg_error <> " Total Documents: #{total_files}."
      end
      if is_integer(total_external_links) do
        msg_error = msg_error <> " Total Links: #{total_external_links}."
      end
      state(@state, :message_error, msg_error)
    end

    :ok
  end
end