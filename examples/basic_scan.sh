#!/bin/bash

echo "🚀 FastDir - Basic Scan Example"
echo "==============================="
echo ""
echo "📝 Running basic scan..."
fastdir -u https://httpbin.org -w /wordlists/common.txt
echo ""
echo "✅ Basic scan complete!"
