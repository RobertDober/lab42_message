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
  @type message_ts :: list(message_t())
  @type result_t :: {:ok|:error, any(), list(message_t)}


  severities = ~w(debug info warning error critical fatal)a
  @severity_values severities |> Enum.zip(Stream.iterate(0, &(&1+1))) |> Enum.into(%{})

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
  Extract a value from an ok result
      iex(13)> extract!(result([], 42))
      42

  However, extracting from an error result is not possible

      iex(14)> extract!({:error, 42, []})
      ** (FunctionClauseError) no function clause matching in Lab42.Message.extract!/1

  """
  @spec extract!(result_t()) :: any()
  def extract!(result)
  def extract!({:ok, value, _anything}), do: value

  @doc """
  Extract messages from a list of messages into a library agnositic form as triples.
  As all the `add_*` functions create a list in reverse order, this function also
  rereverses the message tuples.

      iex(15)> messages =
      ...(15)>   []
      ...(15)>   |> add_error("error1", 1)
      ...(15)>   |> add_info("info2", 2)
      ...(15)>   |> add_warning("warning3", 3)
      ...(15)> messages(messages)
      [ {:error, "error1", 1}, {:warning, "warning3", 3} ]

  As you can see only messages with severity of warning and up are returned.

  One can of course get messages with less severity too:

      iex(16)> messages =
      ...(16)>   []
      ...(16)>   |> add_error("error1", 1)
      ...(16)>   |> add_info("info2", 2)
      ...(16)>   |> add_debug("debug3", 3)
      ...(16)> messages(messages, severity: :info)
      [ {:error, "error1", 1}, {:info, "info2", 2} ]

  And, eventually, for your convenience, instead of `severity: :debug` a shorter and more expressive `:all` can be passed in

      iex(17)> messages =
      ...(17)>   []
      ...(17)>   |> add_error("error1", 1)
      ...(17)>   |> add_info("info2", 2)
      ...(17)>   |> add_debug("debug3", 3)
      ...(17)> messages(messages, :all)
      [ {:error, "error1", 1}, {:info, "info2", 2}, {:debug, "debug3", 3} ]
  """
  @spec messages(ts(), Keyword.t|:all) :: message_ts()
  def messages(messages, options \\ [])
  def messages(messages, :all) do
    messages(messages, severity: :debug)
  end
  def messages(messages, options) do
    min_severity =
      options |> Keyword.get(:severity, :warning) |> severity_value()
    messages
    |> Enum.filter(&(severity_value(&1) >= min_severity))
    |> Enum.map(&_format_message/1)
    |> Enum.reverse
  end

  @doc """
  Wrap a value and error messages into a result tuple

      iex(18)> result([], 42)
      {:ok, 42, []}

  Messages of severity warning or less still deliver a `:ok` result

      iex(19)> messages = []
      ...(19)>   |> add_debug("hello", 1)
      ...(19)>   |> add_info("hello again", 2)
      ...(19)>   |> add_warning("world", 3)
      ...(19)> {:ok, "result", ^messages} = result(messages, "result")
      ...(19)> true
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

        iex(20)> severity_value(:debug)
        0

    The function extracts the severity from a message if necessary

        iex(21)> severity_value(%Lab42.Message{severity: :error})
        3
  """
  def severity_value(message_or_severity)
  def severity_value(%__MODULE__{severity: severity}), do: severity_value(severity)
  def severity_value(severity) do
    # Enum.find_index(@severities, &(&1 == severity)) || 999_999
    Map.get(@severity_values, severity, 999_999)
  end


  @spec _format_message( t() ) :: result_t()
  defp _format_message(%{severity: severity, message: message, location: location}) do
    {severity, message, location}
  end

  @spec _status( ts() ):: :ok|:error
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
