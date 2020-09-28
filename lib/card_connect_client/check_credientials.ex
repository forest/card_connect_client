defmodule CardConnectClient.CheckCredentials do
  @moduledoc false

  def request(%{name: name, base_url: base_url, headers: headers}, body) do
    request = Finch.build(:put, "#{base_url}/", headers, Jason.encode!(body))

    with {:ok, resp} <- Finch.request(request, name) do
      {:ok, Map.from_struct(resp)}
    end
  end
end
