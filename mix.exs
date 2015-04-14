defmodule Krill.Mixfile do
  use Mix.Project

  def project do
    [app: :krill,
     version: "0.0.1",
     #elixir: "~> 1.1-dev",
     #elixir: ">= 1.1.0-dev and < 2.0.0",
     elixir: "~> 1.0.4 or ~> 1.1-dev",
     description: "Filter feeder for shell commands",
     package: package,
     deps: deps,
     escript: escript,
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger, :porcelain],
    ]
  end

  defp package do
    [
      contributors: ["eksperimental"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/eksperimental/krill/"},
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:porcelain, git: "https://github.com/alco/porcelain"},
      {:quaff, github: "qhool/quaff"},
      {:dialyze, "~> 0.1.4"},

      # Docs dependencies
      {:earmark, "~> 0.1.15", only: :docs},
      {:ex_doc, "~> 0.7.2", only: :docs},
    ]
  end

  defp escript do
    [main_module: Krill.CLI]
  end
end
