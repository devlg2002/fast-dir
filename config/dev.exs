import Config

# Development configuration
config :fastdir,
  verbose_logging: true,
  default_threads: 50,
  default_timeout: 5_000

config :logger,
  level: :debug,
  format: "$time $metadata[$level] $message\n"
