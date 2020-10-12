defmodule CardConnectClient.GatewayClient do
  @moduledoc false
  use GenServer

  alias CardConnectClient.GatewayAPI

  # https://developer.cardconnect.com/guides/cardpointe-gateway#cardPointe-gateway-authorization-timeout
  @authorization_timeout 35000

  def child_spec(opts) do
    %{
      id: opts[:name],
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    config =
      get_in(opts, [:config, :gateway_config])
      |> Map.merge(%{http_client_name: get_in(opts, [:config, :http_client_name])})

    {:ok, config}
  end

  def check_credentials(server, body) do
    GenServer.call(server, {:check_credentials, body})
  end

  def authorize_transaction(server, body) do
    GenServer.call(server, {:authorize_transaction, body}, @authorization_timeout)
  end

  def handle_call({:check_credentials, body}, _from, state) do
    response = GatewayAPI.check_credentials(state, body)

    {:reply, response, state}
  end

  def handle_call({:authorize_transaction, body}, _from, state) do
    response =
      GatewayAPI.authorize_transaction(state, body, receive_timeout: @authorization_timeout)

    {:reply, response, state}
  end
end
