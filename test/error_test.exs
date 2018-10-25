defmodule Clover.ErrorTest do
  use ExUnit.Case, async: true

  alias Clover.Error

  describe "message/1" do
    test ":not_exported" do
      message =
        {:not_exported, {MyMod, :my_func, 2}}
        |> Error.exception()
        |> Error.message()

      assert message == "Elixir.MyMod does not export function my_func/2"
    end

    test ":invalid_option" do
      message =
        {:invalid_option, {{MyMod, :my_func, 3}, :invalid, [:valid_one, :valid_two]}}
        |> Error.exception()
        |> Error.message()

      assert message == """
             invalid option for Elixir.MyMod.my_func/3 :invalid
             valid options: [:valid_one, :valid_two]
             """
    end

    test ":unhandled_message" do
      message =
        {:unhandled_message, %{text: "hi"}}
        |> Error.exception()
        |> Error.message()

      assert message == "unhandled message %{text: \"hi\"}"
    end

    test ":invalid_message_handler_return" do
      message =
        {:invalid_message_handler_return, %{action: :invalid}}
        |> Error.exception()
        |> Error.message()

      assert message =~ "invalid handler return"
    end

    test "unknown error" do
      message =
        {:bogus_error, 42}
        |> Error.exception()
        |> Error.message()

      assert message == "unexpected error {:bogus_error, 42}"
    end
  end
end
