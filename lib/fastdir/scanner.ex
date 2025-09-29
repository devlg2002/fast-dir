defmodule FastDir.Scanner do
  @moduledoc """
  Core scanning logic with ultra-high performance
  """

  def start_scan(config) do
    # Start HTTP client pool
    :hackney_pool.start_pool(:fastdir_pool, [
      timeout: config.timeout,
      max_connections: config.threads * 2
    ])

    # Load wordlist
    unless config.silent, do: IO.puts("🔄 Loading wordlist...")
    wordlist = load_wordlist(config.wordlist)
    unless config.silent do
      IO.puts("✅ Loaded #{length(wordlist)} words from wordlist")
    end

    # Generate all possible URLs
    unless config.silent, do: IO.puts("🔄 Generating URL combinations...")
    urls = generate_urls(config.url, wordlist, config.extensions)
    unless config.silent do
      IO.puts("✅ Generated #{length(urls)} total URLs to test")
      IO.puts("🚀 Starting scan with #{config.threads} threads...\n")
    end

    # Start statistics collector
    start_time = System.system_time(:millisecond)
    stats_pid = spawn(fn -> stats_collector(0, length(urls), start_time, config.silent) end)
    send(stats_pid, {:set_total, length(urls)})

    # Start verbose logger if needed
    verbose_pid = if config.verbose do
      spawn(fn -> verbose_logger(config.silent) end)
    else
      nil
    end

    # Start results collector
    results_pid = spawn(fn -> results_collector(config.output, []) end)

    # Start workers
    worker_pool = start_workers(config.threads, config, stats_pid, verbose_pid, results_pid)
    
    # Distribute work
    distribute_work(urls, worker_pool, config)
    
    # Wait for completion
    wait_for_completion(worker_pool)
    
    # Notify completion
    send(stats_pid, {:scan_completed})
    send(results_pid, {:scan_completed})
    Process.sleep(200)  # Give time for final stats and file writes
    
    # Stop pool
    :hackney_pool.stop_pool(:fastdir_pool)
  end

  # ...existing code from start_scan to end of module...

  # The rest of the code is as in fastdir_main_code.ex, from load_wordlist to end of module

  # (Omitted for brevity, as the full code is already provided above)
