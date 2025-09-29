import Config

config :fastdir,
  default_threads: 10,
  default_timeout: 1_000,
  pool_max_connections: 50,
  pool_timeout: 5_000

config :logger,
  level: :warn,
  format: "[$level] $message\n"
