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
  """
  def start_link(opts) do
    name = opts[:name] || raise ArgumentError, "must supply a name"

    config = %{
      http_client_name: http_client_name(name),
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

  @doc """
  Check gateway credentials.

  ## Gateway Configurations

  #{NimbleOptions.docs(@gateway_config_schema)}
  """
  def check_credentials(name, body, opts) do
    GatewayClient.check_credentials(gateway_client_name(name), body, gateway_options!(opts))
  end

  @doc """
  Authorize transaction.

  ## Gateway Configurations

  #{NimbleOptions.docs(@gateway_config_schema)}
  """
  def authorize_transaction(name, body, opts) do
    GatewayClient.authorize_transaction(gateway_client_name(name), body, gateway_options!(opts))
  end

  @doc """
  The inquire service returns information for an individual transaction,
  including its settlement status (setlstat) and the response codes from
  the initial authorization.

  ## Gateway Configurations

  #{NimbleOptions.docs(@gateway_config_schema)}
  """
  def inquire(name, retref, merchid, opts) do
    GatewayClient.inquire(gateway_client_name(name), retref, merchid, gateway_options!(opts))
  end

  defp gateway_options!(opts) do
    case NimbleOptions.validate(opts, @gateway_config_schema) do
      {:ok, valid} ->
        valid_gateway_opts_to_map(valid)

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError,
              "got invalid configuration for gateway: #{Exception.message(error)}"
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

      def check_credentials(body, opts),
        do: CardConnectClient.check_credentials(__MODULE__, body, opts)

      def authorize_transaction(body, opts),
        do: CardConnectClient.authorize_transaction(__MODULE__, body, opts)

      def inquire(retref, merchid, opts),
        do: CardConnectClient.inquire(__MODULE__, retref, merchid, opts)
    end
  end
end
