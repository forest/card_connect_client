defmodule CardConnectClient do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Supervisor

  alias CardConnectClient.GatewayClient

  @gateway_config_schema [
    base_url: [
      type: :string,
      required: true
    ],
    username: [
      type: :string,
      required: true
    ],
    password: [
      type: :string,
      required: true
    ]
  ]

  def child_spec(opts) do
    %{
      id: opts[:name] || raise(ArgumentError, "must supply a name"),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc """
  Start an instance of CardConnectClient.

  ## Options

    * `:name` - The name of your CardConnectClient instance. This field is required.

    ### Gateway Configurations

  #{NimbleOptions.docs(@gateway_config_schema)}
  """
  def start_link(opts) do
    name = opts[:name] || raise ArgumentError, "must supply a name"

    gateway_config = Keyword.get(opts, :gateway, []) |> gateway_options!()

    config = %{
      http_client_name: http_client_name(name),
      gateway_config: gateway_config,
      gateway_client_name: gateway_client_name(name)
    }

    Supervisor.start_link(__MODULE__, config, name: supervisor_name(name))
  end

  @impl true
  def init(config) do
    children = [
      {Finch, [name: config.http_client_name]},
      {GatewayClient, [name: config.gateway_client_name, config: config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def authorize_transaction(name, params) do
    GatewayClient.authorize_transaction(gateway_client_name(name), params)
  end

  def check_credentials(name, body) do
    GatewayClient.check_credentials(gateway_client_name(name), body)
  end

  defp gateway_options!(opts) do
    case NimbleOptions.validate(opts, @gateway_config_schema) do
      {:ok, valid} ->
        valid_gateway_opts_to_map(valid)

      {:error, reason} ->
        raise ArgumentError,
              "got invalid configuration for gateway: #{inspect(reason)}"
    end
  end

  defp valid_gateway_opts_to_map(valid) do
    %{
      base_url: valid[:base_url],
      username: valid[:username],
      password: valid[:password]
    }
  end

  defp supervisor_name(name), do: :"#{name}.Supervisor"
  defp http_client_name(name), do: :"#{name}.HTTPClient"
  defp gateway_client_name(name), do: :"#{name}.GatewayClient"

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        CardConnectClient.child_spec(opts)
      end

      def start_link(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        CardConnectClient.start_link(opts)
      end

      def check_credentials(body), do: CardConnectClient.check_credentials(__MODULE__, body)

      def authorize_transaction(params),
        do: CardConnectClient.authorize_transaction(__MODULE__, params)
    end
  end
end
