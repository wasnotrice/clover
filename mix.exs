defmodule Clover.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :clover,
      version: @version,
      name: "Clover",
      description: description(),
      package: package(),
      source_url: "https://github.com/wasnotrice/clover",
      homepage_url: "https://github.com/wasnotrice/clover",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Clover, []}, registered: [Clover]]
  end

  defp deps do
    [
      {:gen_state_machine, "~> 2.0"},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, "~> 0.10", only: :test},
      {:junit_formatter, "~> 2.2", only: :test}
    ] ++ adapter_deps()
  end

  def adapter_deps do
    _slack = [
      {:slack, "~> 0.14.0"}
    ]
  end

  def description do
    """
    A framework for building chat bots
    """
  end

  def package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Eric Watson"],
      links: %{
        "Source" => "https://github.com/wasnotrice/clover",
        "Issue tracker" => "https://github.com/wasnotrice/clover/issues",
        "Homepage" => "https://github.com/wasnotrice/clover"
      }
    ]
  end

  def docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
