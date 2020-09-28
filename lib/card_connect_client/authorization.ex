defmodule CardConnectClient.Authorization do
  @moduledoc false

  def request(%{name: name, base_url: base_url, headers: headers}, _params) do
    request = Finch.build(:get, "#{base_url}/auth", headers)

    with {:ok, resp} <- Finch.request(request, name),
         {:ok, _json} <- Jason.decode(resp.body) do
      {:ok, Map.from_struct(resp)}
      # case json do
      #   %{"ok" => true} ->
      #     {:ok, "OK"}

      #   %{"error" => error} ->
      #     {:error, error}
      # end
    end
  end
end
