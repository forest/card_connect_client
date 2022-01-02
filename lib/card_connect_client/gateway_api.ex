defmodule CardConnectClient.GatewayAPI do
  @moduledoc false

  alias CardConnectClient.Error

  def check_credentials(config, body) do
    request = build_request(config, :put, "/", body)

    with {:ok, resp} <- make_request(config, request) do
      {:ok, Map.from_struct(resp)}
    end
  end

  def authorize_transaction(config, body, opts \\ []) do
    request = build_request(config, :put, "/auth", body)

    with {:ok, %Finch.Response{} = resp} <- make_request(config, request, opts) do
      case Jason.decode(resp.body) do
        {:ok, json} ->
          {:ok, json}

        {:error, _} ->
          {:error, Error.http_status(resp.status)}
      end
    end
  end

  def inquire(config, retref, merchid, opts \\ []) do
    request = build_request(config, :get, "/inquire/#{retref}/#{merchid}")

    with {:ok, %Finch.Response{} = resp} <- make_request(config, request, opts) do
      case Jason.decode(resp.body) do
        {:ok, json} ->
          {:ok, json}

        {:error, _} ->
          {:error, Error.http_status(resp.status)}
      end
    end
  end

  defp build_request(config, method, path) do
    base_url = base_url_from_config(config)
    headers = headers_from_config(config)

    Finch.build(method, base_url <> path, headers)
  end

  defp build_request(config, method, path, body) do
    base_url = base_url_from_config(config)
    headers = headers_from_config(config)

    Finch.build(method, base_url <> path, headers, Jason.encode!(body))
  end

  defp make_request(config, request, opts \\ []) do
    name = http_client_name_from_config(config)

    response = Finch.request(request, name, opts)

    case response do
      {:ok, _} ->
        response

      {:error, %{reason: reason} = error} ->
        {:error, Error.new(reason, Exception.message(error))}

      {:error, error} ->
        {:error, Error.internal(Exception.message(error))}
    end
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
