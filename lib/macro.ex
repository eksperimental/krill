defmodule Krill.Macro do
  defmacro empty?(value) do
    quote do
      #if ( !unquote(value) || "" == unquote(value) ), do: true
      if ( !unquote(value) || "" == unquote(value) ) do
        true
      else
        false
      end
    end
  end
end