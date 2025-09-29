#!/bin/bash

echo "🚀 FastDir - Advanced Scan Example"
echo "=================================="
echo ""
TARGET_URL="https://httpbin.org"
OUTPUT_FILE="advanced_scan_results.txt"
echo "🎯 Target: $TARGET_URL"
echo "📁 Output: $OUTPUT_FILE"
echo ""
echo "📝 Running advanced scan with:"
echo "  • 150 concurrent threads"
echo "  • Multiple extensions (php, html, js, txt, json)"
echo "  • Custom status codes"
echo "  • Verbose logging"
echo "  • Custom headers for evasion"
echo "  • Output to file"
echo ""
fastdir \
  -u "$TARGET_URL" \
  -w https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt \
  -t 150 \
  -x php,html,js,txt,json,xml,asp,aspx \
  -c 200,204,301,302,307,401,403,500 \
  -v \
  -H "X-Forwarded-For: 127.0.0.1" \
  -H "X-Real-IP: 127.0.0.1" \
  -H "X-Originating-IP: 127.0.0.1" \
  -a "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
  --timeout 15 \
  --max-retries 2 \
  --follow-redirects \
  -o "$OUTPUT_FILE"
echo ""
echo "✅ Advanced scan complete!"
echo "📊 Check results in: $OUTPUT_FILE"
