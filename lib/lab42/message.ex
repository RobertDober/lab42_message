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
  @type ts :: list(t)
  @type message_t :: {severity_t(), String.t, location_t()}
  @type result_t :: {:ok|:error, any(), list(message_t)}

  
  severities = ~w(debug info warning error critical fatal)a
  @severities severities

  for {severity, index} <- severities |> Enum.zip(Stream.iterate(1, &(&1+1))) do
    @doc """
    Create a message with severity :#{severity} and add in front of other messages

        iex(#{index})> Lab42.Message.add_#{severity}([], "Just a #{severity} message", {1, 3})
        [%Lab42.Message{message: "Just a #{severity} message", severity: :#{severity}, location: {1, 3}}]
    """
    @spec unquote( :"add_#{severity}" )(ts(), String.t, any()) :: ts()
    def unquote(:"add_#{severity}")(messages, message, location) do
      [struct(__MODULE__, severity: unquote(severity), location: location, message: message) | messages]
    end
  end

  
end
