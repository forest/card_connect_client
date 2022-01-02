defmodule IntegrationTest do
  use ExUnit.Case, async: false

  setup do
    opts = base_url() |> gateway_options()

    {:ok, gateway_options: opts}
  end

  describe "check credentials" do
    test "successful request, with basic auth header", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      assert {:ok, %{status: 200, body: body}} =
               TestPaymentClient.check_credentials(%{merchid: "800000009033"}, opts)

      assert body =~ ~r/CardConnect REST Servlet/
    end

    test "fails request, with bad basic auth header", %{gateway_options: opts} do
      opts = put_in(opts, [:password], "badbad")

      start_supervised!({TestPaymentClient, []})

      assert {:ok, %{status: 401}} =
               TestPaymentClient.check_credentials(%{merchid: "800000009033"}, opts)
    end
  end

  describe "authorization" do
    test "successful request, with valid transaction details", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      assert {:ok,
              %{
                "amount" => "9.98",
                "expiry" => "0925",
                "merchid" => "800000009033",
                "respcode" => "000",
                "respstat" => "A"
              }} = TestPaymentClient.authorize_transaction(trxn_request(), opts)
    end

    test "fails request, with bad basic auth header", %{gateway_options: opts} do
      opts = put_in(opts, [:password], "badbad")
      start_supervised!({TestPaymentClient, []})

      assert {:error,
              %CardConnectClient.Error{
                message: "Unauthorized",
                reason: :unauthorized
              }} = TestPaymentClient.authorize_transaction(trxn_request(), opts)
    end

    test "fails request, with bad merchid", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      bad_trxn_request = trxn_request() |> Map.put(:merchid, "larry")

      assert {:error,
              %CardConnectClient.Error{
                message: "Unauthorized",
                reason: :unauthorized
              }} = TestPaymentClient.authorize_transaction(bad_trxn_request, opts)
    end

    test "fails request, with bad data", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      bad_trxn_request = trxn_request() |> Map.put(:account, "larry")

      assert {:ok,
              %{
                "account" => "larry",
                "amount" => "0.00",
                "expiry" => "0925",
                "merchid" => "800000009033",
                "respcode" => "11",
                "respstat" => "C",
                "resptext" => "Invalid card"
              }} = TestPaymentClient.authorize_transaction(bad_trxn_request, opts)
    end

    @tag slow: true
    test "fails request, with retry", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      bad_trxn_request = trxn_request() |> Map.put(:account, "4999006200620062")

      response = TestPaymentClient.authorize_transaction(bad_trxn_request, opts)

      assert {:ok,
              %{
                "amount" => "0.00",
                "expiry" => "0925",
                "merchid" => "800000009033",
                "respcode" => "62",
                "respstat" => "B",
                "resptext" => "Timed out"
              }} = response
    end
  end

  describe "inquire" do
    test "successful request, with exisiting transaction", %{gateway_options: opts} do
      start_supervised!({TestPaymentClient, []})

      assert {:ok,
              %{
                "merchid" => merchid,
                "retref" => retref,
                "respstat" => "A"
              }} = TestPaymentClient.authorize_transaction(trxn_request(), opts)

      assert {:ok, %{"retref" => ^retref, "setlstat" => "Authorized"}} =
               TestPaymentClient.inquire(retref, merchid, opts)
    end
  end

  defp trxn_request,
    do: %{
      merchid: "800000009033",
      amount: "998",
      expiry: "0925",
      account: "4444333322221111",
      orderid: "12345"
    }

  defp gateway_options(base_url),
    do: [base_url: base_url, username: "testing", password: "testing123"]

  defp base_url, do: "https://fts-uat.cardconnect.com/cardconnect/rest"
end
