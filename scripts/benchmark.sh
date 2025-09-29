#!/bin/bash
set -e

echo "⚡ FastDir Performance Benchmark"
echo "==============================="
echo ""

TEST_URL="http://httpbin.org"
WORDLIST_SMALL="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-small.txt"

THREAD_COUNTS=(10 25 50 100 150 200)

echo "Threads | Req/s  | Time   | Status"
echo "--------|--------|--------|--------"

for threads in "${THREAD_COUNTS[@]}"; do
    echo -n -e "${threads}      | "
    start_time=$(date +%s.%N)
    output=$(timeout 30s ./fastdir \
        -u "$TEST_URL" \
        -w "$WORDLIST_SMALL" \
        -t "$threads" \
        -s \
        --timeout 5 2>/dev/null || echo "timeout")
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l)
    if [[ "$output" == *"timeout"* ]] || [[ -z "$output" ]]; then
        rate="N/A"
        status="timeout"
    else
        requests_made=$(echo "$output" | wc -l)
        rate=$(echo "scale=1; $requests_made / $duration" | bc -l)
        status="ok"
    fi
    printf "%-6s | %-6s | %-6.1fs | %s\n" "$rate" "$(printf "%.1f" "$duration")" "$status"
done

echo ""
echo "Benchmark complete!"
