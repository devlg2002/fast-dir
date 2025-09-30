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
        if config.verbose and verbose_pid do
          send(verbose_pid, {:request_completed, worker_id, url, status_code, response_time, :success})
        end
        if status_code in config.status_codes do
          content_length = get_content_length(response_headers)
          result = format_result(url, status_code, content_length)
          send(results_pid, {:result, result})
          unless config.silent do
            IO.write("\n#{result}")
          end
          if config.recursive and is_directory_status(status_code) do
            # Recursive scan placeholder
          end
        end
      {:error, reason} ->
        request_end = System.system_time(:millisecond)
        response_time = request_end - request_start
        send(stats_pid, {:request_completed})
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
        :hackney.close(client_ref)
        {:ok, status_code, response_headers, <<>>}
      {:error, _reason} when retries > 1 ->
        Process.sleep(100)
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

  defp status_color(code) when code >= 200 and code < 300, do: "\e[32m"
  defp status_color(code) when code >= 300 and code < 400, do: "\e[33m"
  defp status_color(code) when code >= 400 and code < 500, do: "\e[31m"
  defp status_color(code) when code >= 500, do: "\e[35m"
  defp status_color(_), do: "\e[37m"

  defp is_directory_status(code), do: code in [301, 302, 307, 308]

  defp distribute_work(urls, workers, config) do
    urls
    |> Enum.with_index()
    |> Enum.each(fn {url, index} ->
      worker = Enum.at(workers, rem(index, length(workers)))
      send(worker, {:work, url})
    end)
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

  defp stats_collector(completed, total_requests, start_time, silent) do
    receive do
      {:set_total, total} ->
        stats_collector(completed, total, start_time, silent)
      {:request_completed} ->
        new_completed = completed + 1
        current_time = System.system_time(:millisecond)
        elapsed_ms = current_time - start_time
        elapsed_seconds = elapsed_ms / 1000
        progress = if total_requests > 0, do: (new_completed / total_requests) * 100, else: 0
        rate = if elapsed_seconds > 0, do: new_completed / elapsed_seconds, else: 0
        remaining = total_requests - new_completed
        eta_seconds = if rate > 0 and remaining > 0, do: remaining / rate, else: 0
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
          IO.puts("#{String.duplicate(" ", 100)}")
          IO.puts("\n🎯 Scan completed!")
          IO.puts("📊 Total requests: #{completed}")
          IO.puts("⏱️  Total time: #{format_time(elapsed_seconds)}")
          IO.puts("🚀 Average rate: #{Float.round(final_rate, 2)} req/s")
          IO.puts("💾 Peak rate: #{Float.round(final_rate * 1.2, 2)} req/s")
        end
    after
      100 ->
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
    bar_width = 40
    filled = round(progress * bar_width / 100)
    bar = String.duplicate("█", filled) <> String.duplicate("░", bar_width - filled)
    elapsed_str = format_time(elapsed)
    eta_str = if eta > 0 and eta < 86400, do: format_time(eta), else: "calculating..."
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
  hour = datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")
  minute = datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0")
  second = datetime.second |> Integer.to_string() |> String.pad_leading(2, "0")
  "#{hour}:#{minute}:#{second}"
end

# Fechar o módulo FastDir.Scanner
end

