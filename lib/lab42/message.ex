defmodule Lab42.Message do

  @moduledoc """
  A container for error messages.

  Defining some severities.

  Create results depending on error messages.

  Convenience functions for adding, filtering and sorting messages.
  """

  defstruct location: "lnb or similar", message: "text", severity: :error

  @type severity_t :: :debug | :info | :warning | :error | :critical | :fatal
  @type location_t :: any()
  @type t :: %__MODULE__{location: location_t(), message: String.t, severity: severity_t()}
  @type message_t :: {severity_t(), String.t, location_t()}
  @type result_t :: {:ok|:error, any(), list(message_t)}

  
  for severity <- [:debug] do
    def unquote(:"add_#{severity}")(messages, message, location) do
      [struct(__MODULE__, severity: unquote(severity), location: location, message: message) | messages]
    end
  end

  
end
