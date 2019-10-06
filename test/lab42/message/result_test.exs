defmodule Lab42.Message.ResultTest do
  use ExUnit.Case
  
  import Support.MessageHelper
  import Lab42.Message

  describe "result" do
    test "no messages -> ok" do 
      result   = result([], 42)
      expected = {:ok, 42, []}

      assert result == expected
    end
    test "no error messages -> still ok" do
      messages = ~w[debug warning info]a |> Enum.flat_map(&msg(severity: &1))
      result   = result(messages, 42)
      expected = {:ok, 42, messages}

      assert result == expected
    end
  end

end
