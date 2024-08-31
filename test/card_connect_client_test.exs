defmodule CardConnectClientTest do
  use ExUnit.Case, async: true
  doctest CardConnectClient

  setup do
    bypass = Bypass.open()
    opts = bypass |> base_url() |> gateway_options()

    {:ok, bypass: bypass, gateway_options: opts}
  end

  describe "start_link/1" do
    test "raises if :name is not provided" do
      assert_raise(ArgumentError, ~r/must supply a name/, fn ->
        CardConnectClient.start_link([])
      end)
    end
  end

  describe "check configuration" do
    test "raises when invalid gateway configuration is provided" do
      assert_raise(
        ArgumentError,
        ~r/valid options are: \[:base_url, :username, :password\]/,
        fn ->
          TestPaymentClient.check_credentials(%{merchid: "800000009033"}, bad: 5)
        end
      )

      assert_raise(
        ArgumentError,
        ~r/got invalid configuration for gateway: invalid value for :base_url option: expected string, got: 5/,
        fn ->
          TestPaymentClient.check_credentials(%{merchid: "800000009033"}, base_url: 5)
        end
      )
    end
  end

  describe "check credentials" do
    test "successful put request, with basic auth header", %{
      bypass: bypass,
      gateway_options: opts
    } do
      start_supervised!({TestPaymentClient, []})

      Bypass.expect_once(bypass, "PUT", "/", fn conn ->
        assert {_, "application/json"} =
                 Enum.find(conn.req_headers, fn
                   {"content-type", _} -> true
                   _ -> false
                 end)

        assert {_, "Basic " <> encoded_creds} =
                 Enum.find(conn.req_headers, fn
                   {"authorization", _} -> true
                   _ -> false
                 end)

        assert {:ok, "test:test"} = Base.decode64(encoded_creds)

        Plug.Conn.send_resp(conn, 200, "OK")
      end)

      assert {:ok, %{status: 200}} =
               TestPaymentClient.check_credentials(%{merchid: "800000009033"}, opts)
    end
  end

  defp gateway_options(base_url),
    do: [base_url: base_url, username: "test", password: "test"]

  defp base_url(%{port: port}), do: "http://localhost:#{port}"
end
