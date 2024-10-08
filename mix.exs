defmodule CardConnectClient.MixProject do
  use Mix.Project

  @name "CardConnectClient"
  @version "0.6.1"
  @repo_url "https://github.com/forest/card-connect-client"

  def project do
    [
      app: :card_connect_client,
      version: @version,
      elixir: "~> 1.10",
      description: "An HTTP client for the CardPointe Payment Gateway.",
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: @name,
      source_url: @repo_url,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.17"},
      {:nimble_options, "~> 1.1"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.12"},
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      source_url: @repo_url,
      main: @name
    ]
  end
end
