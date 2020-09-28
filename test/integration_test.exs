defmodule IntegrationTest do
  use ExUnit.Case, async: false

  setup do
    opts = base_url() |> gateway_options()

    {:ok, gateway_options: opts}
  end

  describe "check credentials" do
    test "successful put request, with basic auth header", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, opts})

      assert {:ok, %{status: 200, body: body}} =
               TestPaymentClient.check_credentials(%{merchid: "800000009033"})

      assert body =~ ~r/CardConnect REST Servlet/
    end
  end

  defp gateway_options(base_url),
    do: [gateway: [base_url: base_url, username: "testing", password: "testing123"]]

  defp base_url(), do: "https://fts-uat.cardconnect.com/cardconnect/rest"
end
