<!-- MDOC !-->

A [CardConnect Gateway](https://developer.cardconnect.com/cardconnect-api) Client, built on top of
[Finch](https://github.com/keathley/finch).

## Usage

In order to use CardConnectClient, you must start it and provide a `:name`. Often in your supervision tree:

```elixir
children = [
  {CardConnectClient, name: MyPaymentClient}
]
```

Or, in rare cases, dynamically:

```elixir
CardConnectClient.start_link(name: MyPaymentClient)
```

Once you have started your instance of CardConnectClient, you are ready to start making requests:

```elixir
CardConnectClient.build(:get, "https://hex.pm") |> CardConnectClient.request(MyPaymentClient)
```

You can also configure stuff. See `CardConnectClient.start_link/1` for configuration options.

```elixir
children = [
  {CardConnectClient,
   name: MyConfiguredPaymentClient,
   token: "my-token"}
]
```

<!-- MDOC !-->

## Installation

The package can be installed by adding `card_connect_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:card_connect_client, "~> 0.1"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/card_connect_client](https://hexdocs.pm/card_connect_client).
