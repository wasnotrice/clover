use Mix.Config
config :logger, level: :error

config :junit_formatter,
  report_dir: Path.join(Mix.Project.app_path(), "ex_unit")
