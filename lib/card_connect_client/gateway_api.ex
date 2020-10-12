defmodule CardConnectClient.GatewayAPI do
  @moduledoc false

  def check_credentials(config, body) do
    request = build_request(config, :put, "/", body)

    with {:ok, resp} <- make_request(config, request) do
      {:ok, Map.from_struct(resp)}
    end
  end

  def authorize_transaction(config, body, opts \\ []) do
    request = build_request(config, :put, "/auth", body)

    with {:ok, resp} <- make_request(config, request, opts) do
      case Jason.decode(resp.body) do
        {:ok, json} ->
          {:ok, json}

        {:error, _} ->
          {:error, Map.from_struct(resp)}
      end
    end
  end

  defp build_request(config, method, path, body) when is_atom(method) do
    base_url = base_url_from_config(config)
    headers = headers_from_config(config)

    Finch.build(method, base_url <> path, headers, Jason.encode!(body))
  end

  defp make_request(config, request, opts \\ []) do
    name = http_client_name_from_config(config)

    Finch.request(request, name, opts)
  end

  defp base_url_from_config(%{base_url: base_url}), do: base_url

  defp http_client_name_from_config(%{http_client_name: name}), do: name

  defp headers_from_config(config) do
    [basic_auth_header(config), content_type_header()]
  end

  defp basic_auth_header(%{username: username, password: password}) do
    {"Authorization", "Basic " <> Base.encode64("#{username}:#{password}")}
  end

  defp content_type_header, do: {"Content-Type", "application/json"}
end
