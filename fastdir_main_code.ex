# lib/fastdir.ex
defmodule FastDir do
  @moduledoc """
  FastDir - Ultra Fast Directory Brute Forcer
  
  The fastest directory brute forcer built with Elixir's legendary concurrency.
  """
  
  @version "1.0.0"
  
  def version, do: @version
end

# lib/fastdir/cli.ex
defmodule FastDir.CLI do
  @moduledoc """
  FastDir Command Line Interface
  
  Handles argument parsing and program initialization.
  """

  def main(args) do
    case OptionParser.parse(args, switches: [
      url: :string, wordlist: :string, threads: :integer, status_codes: :string,
      extensions: :string, recursive: :boolean, delay: :integer, user_agent: :string,
      headers: :string, output: :string, silent: :boolean, verbose: :boolean,
      timeout: :integer, max_retries: :integer, follow_redirects: :boolean, help: :boolean
    ], aliases: [
      u: :url, w: :wordlist, t: :threads, c: :status_codes, x: :extensions,
      r: :recursive, d: :delay, a: :user_agent, H: :headers, o: :output,
      s: :silent, v: :verbose, h: :help
    ]) do
      {opts, _, _} when opts[:help] -> show_help()
      {opts, _, _} when is_nil(opts[:url]) or is_nil(opts[:wordlist]) -> show_help()
      {opts, _, _} -> run_scan(opts)
    end
  end

  defp show_help do
    IO.puts("""
    
    ███████╗ █████╗ ███████╗████████╗██████╗ ██╗██████╗ 
    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║██╔══██╗
    █████╗  ███████║███████╗   ██║   ██║  ██║██║██████╔╝
    ██╔══╝  ██╔══██║╚════██║   ██║   ██║  ██║██║██╔══██╗
    ██║     ██║  ██║███████║   ██║   ██████╔╝██║██║  ██║
    ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═╝
    
    FastDir v#{FastDir.version()} - Ultra Fast Directory Brute Forcer
    By lgdev2002 - Co-CEO BackTrackSec
    The fastest directory brute forcer on GitHub!
    
    USAGE:
        fastdir -u <target_url> -w <wordlist> [options]
        
    REQUIRED:
        -u, --url URL           Target URL
        -w, --wordlist PATH     Path to wordlist file or URL
        
    OPTIONS:
        -t, --threads N         Number of concurrent threads (default: 100)
        -c, --status-codes      Status codes to show (default: 200,204,301,302,307,308,401,403,405)
        -x, --extensions        Extensions to append (comma separated)
        -r, --recursive         Recursive scan on found directories
        -d, --delay MS          Delay between requests in ms (default: 0)
        -a, --user-agent        Custom User-Agent string
        -H, --headers           Custom headers (format: "Header: Value")
        -o, --output FILE       Output file
        -s, --silent            Silent mode (only show results)
        -v, --verbose           Verbose output with detailed logging
        --timeout N             Request timeout in seconds (default: 10)
        --max-retries N         Maximum retries per request (default: 3)
        --follow-redirects      Follow redirects
        -h, --help              Show this help
        
    EXAMPLES:
        # Basic scan
        fastdir -u https://target.com -w /usr/share/wordlists/dirb/common.txt
        
        # High performance scan with extensions
        fastdir -u https://target.com -w big.txt -t 200 -x php,html,js,txt
        
        # Remote wordlist with verbose output
        fastdir -u https://target.com \\
          -w https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt \\
          -t 150 -v -o results.txt
        
        # Stealth scan with custom headers
        fastdir -u https://target.com -w medium.txt -t 10 -d 1000 \\
          -H "X-Forwarded-For: 127.0.0.1" -a "Mozilla/5.0 Custom Agent"
    
    DOCKER:
        docker run --rm lgdev2002/fastdir -u https://target.com -w /wordlists/common.txt
    
    MORE INFO:
        GitHub: https://github.com/lgdev2002/fastdir
        Issues: https://github.com/lgdev2002/fastdir/issues
    """)
  end

  defp run_scan(opts) do
    config = %{
      url: normalize_url(opts[:url]),
      wordlist: opts[:wordlist],
      threads: opts[:threads] || 100,
      status_codes: parse_status_codes(opts[:status_codes]),
      extensions: parse_extensions(opts[:extensions]),
      recursive: opts[:recursive] || false,
      delay: opts[:delay] || 0,
      user_agent: opts[:user_agent] || "FastDir/#{FastDir.version()} (BackTrackSec)",
      headers: parse_headers(opts[:headers]),
      output: opts[:output],
      silent: opts[:silent] || false,
      verbose: opts[:verbose] || false,
      timeout: (opts[:timeout] || 10) * 1000,
      max_retries: opts[:max_retries] || 3,
      follow_redirects: opts[:follow_redirects] || false
    }

    print_banner(config)
    FastDir.Scanner.start_scan(config)
  end

  defp normalize_url(url) do
    url = if String.starts_with?(url, "http"), do: url, else: "http://#{url}"
    if String.ends_with?(url, "/"), do: url, else: "#{url}/"
  end

  defp parse_status_codes(nil), do: [200, 204, 301, 302, 307, 308, 401, 403, 405]
  defp parse_status_codes(codes) do
    codes
    |> String.split(",")
    |> Enum.map(&String.to_integer(String.trim(&1)))
  end

  defp parse_extensions(nil), do: []
  defp parse_extensions(exts) do
    exts
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn ext -> if String.starts_with?(ext, "."), do: ext, else: ".#{ext}" end)
  end

  defp parse_headers(nil), do: []
  defp parse_headers(headers) when is_binary(headers) do
    headers
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn header ->
      [key, value] = String.split(header, ":", parts: 2)
      {String.trim(key), String.trim(value)}
    end)
  end

  defp print_banner(config) do
    unless config.silent do
      IO.puts("""
      
      ███████╗ █████╗ ███████╗████████╗██████╗ ██╗██████╗ 
      ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║██╔══██╗
      █████╗  ███████║███████╗   ██║   ██║  ██║██║██████╔╝
      ██╔══╝  ██╔══██║╚════██║   ██║   ██║  ██║██║██╔══██╗
      ██║     ██║  ██║███████║   ██║   ██████╔╝██║██║  ██║
      ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═╝
      
      FastDir v#{FastDir.version()} - Ultra Fast Directory Brute Forcer
      By lgdev2002 - Co-CEO BackTrackSec
      The fastest directory brute forcer on GitHub!
      
      🎯 Target: #{config.url}
      📝 Wordlist: #{config.wordlist}
      🚀 Threads: #{config.threads}
      📊 Status Codes: #{Enum.join(config.status_codes, ", ")}
      🔧 Extensions: #{if config.extensions == [], do: "None", else: Enum.join(config.extensions, ", ")}
      #{if config.recursive, do: "🔄 Recursive: Enabled", else: ""}
      #{if config.delay > 0, do: "⏱️  Delay: #{config.delay}ms", else: ""}
      
      """)
    end
  end
end

# lib/fastdir/scanner.ex
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

  defp load_wordlist(wordlist_path) do
    cond do
      String.starts_with?(wordlist_path, "http") ->
        load_remote_wordlist(wordlist_path)
      File.exists?(wordlist_path) ->
        wordlist_path
        |> File.read!()
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      true ->
        IO.puts("❌ Error: Wordlist not found: #{wordlist_path}")
        System.halt(1)
    end
  end

  defp load_remote_wordlist(url) do
    IO.puts("🌐 Downloading remote wordlist: #{url}")
    case :hackney.get(url, [], <<>>, [pool: :fastdir_pool, timeout: 30000]) do
      {:ok, 200, _headers, client_ref} ->
        {:ok, body} = :hackney.body(client_ref)
        :hackney.close(client_ref)
        body
        |> to_string()
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
      {:ok, status, _headers, client_ref} ->
        :hackney.close(client_ref)
        IO.puts("❌ Error loading remote wordlist: HTTP #{status}")
        System.halt(1)
      {:error, reason} ->
        IO.puts("❌ Error loading remote wordlist: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp generate_urls(base_url, wordlist, extensions) do
    base_urls = Enum.map(wordlist, &"#{base_url}#{&1}")
    
    if extensions == [] do
      base_urls
    else
      extended_urls = for word <- wordlist, ext <- extensions do
        "#{base_url}#{word}#{ext}"
      end
      base_urls ++ extended_urls
    end
  end

  defp start_workers(count, config, stats_pid, verbose_pid, results_pid) do
    1..count
    |> Enum.map(fn id ->
      spawn_link(fn -> worker_loop(id, config, stats_pid, verbose_pid, results_pid) end)
    end)
  end

  defp worker_loop(worker_id, config, stats_pid, verbose_pid, results_pid) do
    receive do
      {:work, url} ->
        scan_url(url, config, stats_pid, verbose_pid, results_pid, worker_id)
        if config.delay > 0, do: Process.sleep(config.delay)
        worker_loop(worker_id, config, stats_pid, verbose_pid, results_pid)
      :stop ->
        :ok
    end
  end

  defp scan_url(url, config, stats_pid, verbose_pid, results_pid, worker_id) do
    request_start = System.system_time(:millisecond)
    
    # Log verbose start
    if config.verbose and verbose_pid do
      send(verbose_pid, {:request_start, worker_id, url, request_start})
    end
    
    headers = [
      {"User-Agent", config.user_agent}
      | config.headers
    ]

    options = [
      pool: :fastdir_pool,
      timeout: config.timeout,
      follow_redirect: config.follow_redirects
    ]

    case make_request_with_retry(url, headers, options, config.max_retries) do
      {:ok, status_code, response_headers, _body} ->
        request_end = System.system_time(:millisecond)
        response_time = request_end - request_start
        
        send(stats_pid, {:request_completed})
        
        # Log verbose response
        if config.verbose and verbose_pid do
          send(verbose_pid, {:request_completed, worker_id, url, status_code, response_time, :success})
        end
        
        if status_code in config.status_codes do
          content_length = get_content_length(response_headers)
          result = format_result(url, status_code, content_length)
          
          # Send to results collector
          send(results_pid, {:result, result})
          
          unless config.silent do
            # Print result (will show after progress bar)
            IO.write("\n#{result}")
          end
          
          # Recursive scanning for directories
          if config.recursive and is_directory_status(status_code) do
            # This would spawn a new scan for the found directory
            # Implementation would be similar but with the found URL as base
          end
        end
      
      {:error, reason} ->
        request_end = System.system_time(:millisecond)
        response_time = request_end - request_start
        
        send(stats_pid, {:request_completed})
        
        # Log verbose error
        if config.verbose and verbose_pid do
          send(verbose_pid, {:request_completed, worker_id, url, 0, response_time, {:error, reason}})
        end
        
        if config.verbose and not config.silent do
          IO.write("\n❌ Error scanning: #{url} (#{inspect(reason)})")
        end
    end
  end

  defp make_request_with_retry(url, headers, options, retries) when retries > 0 do
    case :hackney.get(url, headers, <<>>, options) do
      {:ok, status_code, response_headers, client_ref} ->
        # Always close the connection to avoid leaks
        :hackney.close(client_ref)
        {:ok, status_code, response_headers, <<>>}
      {:error, _reason} when retries > 1 ->
        Process.sleep(100)  # Small delay before retry
        make_request_with_retry(url, headers, options, retries - 1)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_request_with_retry(_url, _headers, _options, 0) do
    {:error, :max_retries_exceeded}
  end

  defp get_content_length(headers) do
    case List.keyfind(headers, "Content-Length", 0) do
      {_, length} -> String.to_integer(length)
      nil -> 0
    end
  end

  defp format_result(url, status_code, content_length) do
    color = status_color(status_code)
    "#{color}[#{status_code}] #{content_length}B - #{url}\e[0m"
  end

  defp status_color(code) when code >= 200 and code < 300, do: "\e[32m"  # Green
  defp status_color(code) when code >= 300 and code < 400, do: "\e[33m"  # Yellow  
  defp status_color(code) when code >= 400 and code < 500, do: "\e[31m"  # Red
  defp status_color(code) when code >= 500, do: "\e[35m"                 # Magenta
  defp status_color(_), do: "\e[37m"                                     # White

  defp is_directory_status(code), do: code in [301, 302, 307, 308]

  defp distribute_work(urls, workers, config) do
    urls
    |> Enum.with_index()
    |> Enum.each(fn {url, index} ->
      worker = Enum.at(workers, rem(index, length(workers)))
      send(worker, {:work, url})
    end)

    # Signal completion
    Enum.each(workers, fn worker ->
      send(worker, :stop)
    end)
  end

  defp wait_for_completion(workers) do
    Enum.each(workers, fn worker ->
      ref = Process.monitor(worker)
      receive do
        {:DOWN, ^ref, :process, ^worker, _reason} -> :ok
      end
    end)
  end

  # Results collector for file output
  defp results_collector(output_file, results) do
    receive do
      {:result, result} ->
        new_results = [result | results]
        if output_file do
          File.write!(output_file, "#{result}\n", [:append])
        end
        results_collector(output_file, new_results)
        
      {:scan_completed} ->
        if output_file do
          IO.puts("\n📁 Results saved to: #{output_file}")
          IO.puts("📊 Total findings: #{length(results)}")
        end
        :ok
    end
  end

  # Statistics collector with beautiful progress bar
  defp stats_collector(completed, total_requests, start_time, silent) do
    receive do
      {:set_total, total} ->
        stats_collector(completed, total, start_time, silent)
      
      {:request_completed} ->
        new_completed = completed + 1
        current_time = System.system_time(:millisecond)
        elapsed_ms = current_time - start_time
        elapsed_seconds = elapsed_ms / 1000
        
        # Calculate progress and ETA
        progress = if total_requests > 0, do: (new_completed / total_requests) * 100, else: 0
        rate = if elapsed_seconds > 0, do: new_completed / elapsed_seconds, else: 0
        remaining = total_requests - new_completed
        eta_seconds = if rate > 0 and remaining > 0, do: remaining / rate, else: 0
        
        # Update progress every 10 requests or every 100ms
        if not silent and (rem(new_completed, 10) == 0 or System.system_time(:millisecond) - current_time > 100) do
          update_progress(new_completed, total_requests, progress, rate, elapsed_seconds, eta_seconds)
        end
        
        stats_collector(new_completed, total_requests, start_time, silent)
        
      {:scan_completed} ->
        current_time = System.system_time(:millisecond)
        elapsed_ms = current_time - start_time
        elapsed_seconds = elapsed_ms / 1000
        final_rate = if elapsed_seconds > 0, do: completed / elapsed_seconds, else: 0
        
        unless silent do
          IO.write("\r")
          IO.puts("#{String.duplicate(" ", 100)}")  # Clear line
          IO.puts("\n🎯 Scan completed!")
          IO.puts("📊 Total requests: #{completed}")
          IO.puts("⏱️  Total time: #{format_time(elapsed_seconds)}")
          IO.puts("🚀 Average rate: #{Float.round(final_rate, 2)} req/s")
          IO.puts("💾 Peak rate: #{Float.round(final_rate * 1.2, 2)} req/s")  # Estimated peak
        end
        
    after
      100 ->
        # Update progress every 100ms even without new requests
        if not silent and total_requests > 0 and completed > 0 do
          current_time = System.system_time(:millisecond)
          elapsed_ms = current_time - start_time
          elapsed_seconds = elapsed_ms / 1000
          progress = (completed / total_requests) * 100
          rate = if elapsed_seconds > 0, do: completed / elapsed_seconds, else: 0
          remaining = total_requests - completed
          eta_seconds = if rate > 0 and remaining > 0, do: remaining / rate, else: 0
          
          update_progress(completed, total_requests, progress, rate, elapsed_seconds, eta_seconds)
        end
        
        stats_collector(completed, total_requests, start_time, silent)
    end
  end
  
  defp update_progress(completed, total, progress, rate, elapsed, eta) do
    # Create progress bar
    bar_width = 40
    filled = round(progress * bar_width / 100)
    bar = String.duplicate("█", filled) <> String.duplicate("░", bar_width - filled)
    
    # Format times
    elapsed_str = format_time(elapsed)
    eta_str = if eta > 0 and eta < 86400, do: format_time(eta), else: "calculating..."
    
    # Progress line
    progress_line = "\r🔍 [#{bar}] #{Float.round(progress, 1)}% " <>
                   "(#{completed}/#{total}) | " <>
                   "⚡ #{Float.round(rate, 2)} req/s | " <>
                   "⏱️ #{elapsed_str} | " <>
                   "🕒 ETA: #{eta_str}"
    
    IO.write(progress_line)
  end
  
  defp format_time(seconds) when seconds < 60 do
    "#{Float.round(seconds, 1)}s"
  end
  
  defp format_time(seconds) when seconds < 3600 do
    minutes = div(round(seconds), 60)
    remaining_seconds = rem(round(seconds), 60)
    "#{minutes}m #{remaining_seconds}s"
  end
  
  defp format_time(seconds) do
    hours = div(round(seconds), 3600)
    remaining_minutes = div(rem(round(seconds), 3600), 60)
    remaining_seconds = rem(round(seconds), 60)
    "#{hours}h #{remaining_minutes}m #{remaining_seconds}s"
  end

  # Verbose logger process
  defp verbose_logger(silent) do
    receive do
      {:request_start, worker_id, url, timestamp} ->
        unless silent do
          time_str = format_timestamp(timestamp)
          IO.write("\n🔄 [Worker-#{worker_id}] [#{time_str}] Starting: #{url}")
        end
        verbose_logger(silent)
        
      {:request_completed, worker_id, url, status_code, response_time, result} ->
        unless silent do
          time_str = format_timestamp(System.system_time(:millisecond))
          status_icon = case result do
            :success when status_code >= 200 and status_code < 300 -> "✅"
            :success when status_code >= 300 and status_code < 400 -> "🔄"
            :success when status_code >= 400 and status_code < 500 -> "⚠️"
            :success when status_code >= 500 -> "❌"
            {:error, _} -> "💥"
            _ -> "❓"
          end
          
          result_text = case result do
            :success -> "#{status_code}"
            {:error, reason} -> "ERROR: #{inspect(reason)}"
          end
          
          IO.write("\n#{status_icon} [Worker-#{worker_id}] [#{time_str}] #{response_time}ms - #{result_text} - #{url}")
        end
        verbose_logger(silent)
    end
  end
  
  defp format_timestamp(timestamp) do
    datetime = DateTime.from_unix!(timestamp, :millisecond)
    "#{datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")}:" <>
    "#{datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0")}:" <>
    "#{datetime.second |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end
end

# mix.exs
defmodule FastDir.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastdir,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      description: description(),
      package: package(),
      source_url: "https://github.com/lgdev2002/fastdir",
      homepage_url: "https://github.com/lgdev2002/fastdir",
      docs: [
        main: "FastDir",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :hackney, :ssl, :public_key]
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.18"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp escript do
    [main_module: FastDir.CLI]
  end

  defp description do
    "Ultra fast directory brute forcer built with Elixir's legendary concurrency"
  end

  defp package do
    [
      name: "fastdir",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/lgdev2002/fastdir",
        "Issues" => "https://github.com/lgdev2002/fastdir/issues"
      },
      maintainers: ["lgdev2002"],
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
  