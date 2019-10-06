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
    # Make add_message
    @doc """
    Create a message with severity :#{severity} and add in front of other messages

        iex(#{2*index})> add_#{severity}([], "Just a #{severity} message", {1, 3})
        [%Lab42.Message{message: "Just a #{severity} message", severity: :#{severity}, location: {1, 3}}]
    """
    @spec unquote( :"add_#{severity}" )(ts(), String.t, any()) :: ts()
    def unquote(:"add_#{severity}")(messages, message, location) do
      [unquote(:"make_#{severity}")(message, location)|messages]
    end
  end

  for {severity, index} <- severities |> Enum.zip(Stream.iterate(1, &(&1+1))) do
    # Make make_message
    @doc """
    Create a message with severity :#{severity}

        iex(#{2*index + 1})> make_#{severity}("Just a #{severity} message", {1, 3})
        %Lab42.Message{message: "Just a #{severity} message", severity: :#{severity}, location: {1, 3}}
    """
    @spec unquote( :"make_#{severity}" )(String.t, any()) :: t()
    def unquote(:"make_#{severity}")(message, location) do
      struct(__MODULE__, severity: unquote(severity), location: location, message: message)
    end
  end

  @doc """
  Wrap a value and error messages into a result tuple

      iex(13)> result([], 42)
      {:ok, 42, []}

  Messages of severity warning or less still deliver a `:ok` result

      iex(14)> messages = []
      ...(14)>   |> add_debug("hello", 1)
      ...(14)>   |> add_info("hello again", 2)
      ...(14)>   |> add_warning("world", 3)
      ...(14)> {:ok, "result", ^messages} = result(messages, "result")
      ...(14)> true
      true

  """
  @spec result( ts(), any() ) :: result_t()
  def result(messages, value) do
    status = _status(messages)
    {status, value, messages}
  end

  @doc """
    Assigns to each severity a numerical value, where a higher value indicates
    a higher severity.

        iex(15)> severity_value(:debug)
        0

    The function extracts the severity from a message if necessary

        iex(16)> severity_value(%Lab42.Message{severity: :error})
        3
  """
  def severity_value(message_or_severity)
  def severity_value(%__MODULE__{severity: severity}), do: severity_value(severity)
  def severity_value(severity) do
    Enum.find_index(@severities, &(&1 == severity)) || 999_999
  end


  defp _status(messages) do
    severity_max =
      messages
        |> Enum.max_by(&severity_value/1, fn -> :debug end)
        |> severity_value()
    if severity_max < severity_value(:error),
      do: :ok,
      else: :error
  end
end
