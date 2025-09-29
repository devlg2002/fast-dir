
import Config

# FastDir configuration
config :fastdir,
	default_threads: 100,
	default_timeout: 10_000,
	default_user_agent: "FastDir/1.0 (BackTrackSec)",
	default_status_codes: [200, 204, 301, 302, 307, 308, 401, 403, 405],
	pool_max_connections: 1000,
	pool_timeout: 30_000

# Environment specific configuration
import_config "#{config_env()}.exs"
