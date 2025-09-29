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
        fastdir -u https://target.com \
          -w https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt \
          -t 150 -v -o results.txt
        
        # Stealth scan with custom headers
        fastdir -u https://target.com -w medium.txt -t 10 -d 1000 \
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
