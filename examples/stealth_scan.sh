#!/bin/bash

echo "🚀 FastDir - Stealth Scan Example"
echo "================================="
echo ""
TARGET_URL="https://httpbin.org"
echo "🤷 Running stealth scan with:"
echo "  • Low thread count (10)"
echo "  • Request delays (2000ms)"
echo "  • Realistic User-Agent"
echo "  • Custom headers for evasion"
echo "  • Extended timeout"
echo ""
fastdir \
  -u "$TARGET_URL" \
  -w /wordlists/small.txt \
  -t 10 \
  -d 2000 \
  -a "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
  -H "Accept-Language: en-US,en;q=0.5" \
  -H "Accept-Encoding: gzip, deflate" \
  -H "Connection: keep-alive" \
  -H "Upgrade-Insecure-Requests: 1" \
  --timeout 30 \
  --max-retries 1
echo ""
echo "✅ Stealth scan complete!"
echo "🔍 This scan mimics normal browser behavior"
