# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :porcelain, driver: Porcelain.Driver.Goon

config :krill, config: [
  sample: %{
    title: "Sample Command",
    command_name: "echo.sh",
    command: "./test/fixtures/echo.sh",
    timeout: 1000, 
    },
  htmlproof: %{
    title: "Validate site with Htmlproof",
    command_name: "htmlproof",
    command: "htmlproof ./test/fixtures/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --disable-external",
    #command: "htmlproof ~/git/eksperimental/elixir-lang.github.com/_site --file-ignore /docs/ --only-4xx --check-favicon --check-html --check-external-hash",
    timeout: 1000 * 60 * 15, # 15mins
    },
]

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger,
#       level: :info
#
#     config :logger, :console,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
