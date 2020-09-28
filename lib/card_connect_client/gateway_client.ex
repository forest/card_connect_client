defmodule CardConnectClient.GatewayClient do
  @moduledoc false
  use GenServer

  alias CardConnectClient.{Authorization, CheckCredentials}

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

  def authorize_transaction(server, params) do
    GenServer.call(server, {:authorize_transaction, params})
  end

  def check_credentials(server, body) do
    GenServer.call(server, {:check_credentials, body})
  end

  def handle_call({:check_credentials, body}, _from, state) do
    response = CheckCredentials.request(request_config(state), body)

    {:reply, response, state}
  end

  def handle_call({:authorize_transaction, params}, _from, state) do
    response = Authorization.request(request_config(state), params)

    {:reply, response, state}
  end

  defp basic_auth_header(%{username: username, password: password}) do
    {"Authorization", "Basic " <> Base.encode64("#{username}:#{password}")}
  end

  defp content_type_header, do: {"Content-Type", "application/json"}

  defp request_config(%{http_client_name: name, base_url: base_url} = state) do
    headers = [basic_auth_header(state), content_type_header()]
    %{name: name, base_url: base_url, headers: headers}
  end
end
