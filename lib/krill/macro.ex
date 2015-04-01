defmodule Krill.Macro do

  @doc """
  Checks if `term` is a falsey value, and empty string or an empty list.  
  """
  @spec empty?(term) :: boolean
  defmacro empty?(value) do
    quote do
      if ( !unquote(value) || "" == unquote(value) || [] == unquote(value) ) do
        true
      else
        false
      end
    end
  end
end