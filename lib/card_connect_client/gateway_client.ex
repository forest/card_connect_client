defmodule CardConnectClient.GatewayClient do
  @moduledoc false
  use GenServer

  alias CardConnectClient.GatewayAPI

  # https://developer.cardconnect.com/guides/cardpointe-gateway#cardPointe-gateway-authorization-timeout
  @authorization_timeout 35_000

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
    config = %{http_client_name: get_in(opts, [:config, :http_client_name])}

    {:ok, config}
  end

  def check_credentials(server, body, opts) do
    GenServer.call(server, {:check_credentials, body, opts})
  end

  def authorize_transaction(server, body, opts) do
    GenServer.call(server, {:authorize_transaction, body, opts}, @authorization_timeout)
  end

  def handle_call({:check_credentials, body, opts}, _from, state) do
    response = GatewayAPI.check_credentials(gateway_config(opts, state), body)

    {:reply, response, state}
  end

  def handle_call({:authorize_transaction, body, opts}, _from, state) do
    response =
      GatewayAPI.authorize_transaction(gateway_config(opts, state), body,
        receive_timeout: @authorization_timeout
      )

    {:reply, response, state}
  end

  defp gateway_config(opts, %{http_client_name: http_client_name}) when is_map(opts) do
    %{http_client_name: http_client_name}
    |> Map.merge(opts)
  end
end
