defmodule Lab42.Message.AddMessageTest do
  use ExUnit.Case

  import Lab42.Message

  describe "add_*" do
    test "debug" do
      messages = add_debug([], "debug message", 42)
      expected = msg(message: "debug message", location: 42, severity: :debug)

      assert messages == expected
    end
  end

  defp msg(options) do
    [ struct(Lab42.Message, options) ]
  end
  
end
