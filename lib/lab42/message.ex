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
  @type message_list_t :: list(t()|message_t())
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
  Returns the maximum priority of messages
  A list of messages can be passed in 

      iex(15)> messages =
      ...(15)>   []
      ...(15)>   |> add_error("error1", 1)
      ...(15)>   |> add_info("info2", 2)
      ...(15)>   |> add_warning("warning3", 3)
      ...(15)> max_severity(messages)
      :error

  However a list of message tuples is also allowed

      iex(16)> messages =
      ...(16)>   []
      ...(16)>   |> add_error("error1", 1)
      ...(16)>   |> add_fatal("fatal2", 2)
      ...(16)>   |> add_warning("warning3", 3)
      ...(16)>   |> messages()
      ...(16)> max_severity(messages)
      :fatal

  In accordance of the robustness principle the last can even be mixed

      iex(17)> messages =
      ...(17)>   []
      ...(17)>   |> add_error("what an error", 42)
      ...(17)>   |> add_info("what an info", 42)
      ...(17)> max_severity([{:critical, "", nil}|messages])
      :critical

  And last, but not least it might be convenient to get the severity_value instead of
  the symbolic severity

      iex(18)> messages =
      ...(18)>   []
      ...(18)>   |> add_error("what an error", 42)
      ...(18)>   |> add_info("what an info", 42)
      ...(18)> max_severity([{:critical, "", nil}|messages], value: true)
      4

  """
  @spec max_severity( message_list_t(), Keyword.t ) :: severity_t()
  def max_severity(message_list, opts \\ []), do: _max_severity(message_list, :debug, Keyword.get(opts, :value))

  @doc """
  Extract messages from a list of messages into a library agnositic form as triples.
  As all the `add_*` functions create a list in reverse order, this function also
  rereverses the message tuples.

      iex(19)> messages =
      ...(19)>   []
      ...(19)>   |> add_error("error1", 1)
      ...(19)>   |> add_info("info2", 2)
      ...(19)>   |> add_warning("warning3", 3)
      ...(19)> messages(messages)
      [ {:error, "error1", 1}, {:warning, "warning3", 3} ]

  As you can see only messages with severity of warning and up are returned.

  One can of course get messages with less severity too:

      iex(20)> messages =
      ...(20)>   []
      ...(20)>   |> add_error("error1", 1)
      ...(20)>   |> add_info("info2", 2)
      ...(20)>   |> add_debug("debug3", 3)
      ...(20)> messages(messages, severity: :info)
      [ {:error, "error1", 1}, {:info, "info2", 2} ]

  And, eventually, for your convenience, instead of `severity: :debug` a shorter and more expressive `:all` can be passed in

      iex(21)> messages =
      ...(21)>   []
      ...(21)>   |> add_error("error1", 1)
      ...(21)>   |> add_info("info2", 2)
      ...(21)>   |> add_debug("debug3", 3)
      ...(21)> messages(messages, :all)
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
  Wrap a value and error messages into a result tuple, messages themselves
  are converted to message tuples as with `messages`. Also warnings still
  deliver an `:ok` reesult.œ

      iex(22)> messages = []
      ...(22)>   |> add_debug("hello", 1)
      ...(22)>   |> add_info("hello again", 2)
      ...(22)>   |> add_warning("world", 3)
      ...(22)> result(messages, "result")
      {:ok, "result", [{:warning, "world", 3}]}

  However the presence of errors or worse returns an `:error` result.
  N.B. that the input can be a mixture of `Lab42.Message` structs and
  agnostic tuples.

      iex(23)> messages = [{:fatal, "that was not good", 0}]
      ...(23)>   |> add_debug("hello", 1)
      ...(23)> result(messages, "result")
      {:error, "result", [{:fatal, "that was not good", 0}]}

  As with `messages` one can control what level of errors shall be included, here
  is an example where warnings are surpressed

      iex(24)> messages = []
      ...(24)>   |> add_error("hello", 1)
      ...(24)>   |> add_info("hello again", 2)
      ...(24)>   |> add_warning("world", 3)
      ...(24)> result(messages, 42, severity: :error)
      {:error, 42, [{:error, "hello", 1}]}

  """
  @spec result( ts(), any(), Keyword.t ) :: result_t()
  def result(messages, value, options \\ []) do
    status = _status(messages)
    {status, value, messages(messages, severity: Keyword.get(options, :severity, :warning))}
  end

  @doc """
    Assigns to each severity a numerical value, where a higher value indicates
    a higher severity.

        iex(24)> severity_value(:debug)
        0

    The function extracts the severity from a message if necessary

        iex(25)> severity_value(%Lab42.Message{severity: :error})
        3
  """
  @spec severity_value( t() | severity_t() | message_t()) :: number()
  def severity_value(message_or_severity)
  def severity_value(%__MODULE__{severity: severity}), do: severity_value(severity)
  def severity_value({severity, _, _}), do: severity_value(severity)
  def severity_value(severity) do
    Map.get(@severity_values, severity, 999_999)
  end


  @spec _format_message( t() | message_t() ) :: message_t()
  defp _format_message({_, _, _}=message), do: message
  defp _format_message(%{severity: severity, message: message, location: location}) do
    {severity, message, location}
  end

  @spec _max( severity_t(), severity_t() ) :: severity_t()
  defp _max(lhs_severity, rhs_severity)
  defp _max(lhs, rhs) do
    if severity_value(lhs) > severity_value(rhs),
      do: lhs,
      else: rhs
  end

  @spec _max_severity( message_list_t(), severity_t(), any() ) :: severity_t() | number()
  defp _max_severity(message_list, current_max, value?)
  defp _max_severity([], current_max, value?) do
    if value?,
      do: severity_value(current_max),
    else: current_max
  end
  defp _max_severity([{severity, _, _}|rest], current_max, value?), do:
    _max_severity(rest, _max(severity, current_max), value?)
  defp _max_severity([%{severity: severity}|rest], current_max, value?), do:
    _max_severity(rest, _max(severity, current_max), value?)

  @spec _status( message_list_t() ):: :ok|:error
  defp _status(messages) do
    severity_max = _max_severity(messages, :debug, true)
    if severity_max < severity_value(:error),
      do: :ok,
      else: :error
  end
end
