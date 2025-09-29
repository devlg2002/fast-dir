import Config

config :fastdir,
  default_threads: 200,
  default_timeout: 15_000,
  pool_max_connections: 2000,
  pool_timeout: 60_000

config :logger,
  level: :info,
  format: "$time [$level] $message\n"
