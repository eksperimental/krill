defmodule Krill.Mixfile do
  use Mix.Project

  def project do
    [app: :krill,
     version: "0.0.1",
     #elixir: "~> 1.1-dev",
     #elixir: ">= 1.1.0-dev and < 2.0.0",
     elixir: "~> 1.0.2 or ~> 1.1-dev",
     deps: deps,
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger, :porcelain, ],
      #mod: {Krill, []},
      mod: {Htmlproof, []},
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
      {:sh, git: "https://github.com/devinus/sh", tag: "1.1.1"},
      #{:erlexec, git: "https://github.com/saleyn/erlexec"},
      {:porcelain, git: "https://github.com/alco/porcelain"},
    ]
  end
end
