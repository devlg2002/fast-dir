
.PHONY: build install test clean help


APP_NAME = fastdir
VERSION = 1.0.0


help:
	@echo "FastDir - Ultra Fast Directory Brute Forcer"
	@echo "Available commands:"
	@echo "  make build    - Build the application"
	@echo "  make install  - Install locally"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean build artifacts"

build:
	@echo "🔨 Building FastDir..."
	mix deps.get
	mix escript.build
	@echo "✅ Build complete!"

install: build
	@echo "📦 Installing FastDir..."
	sudo cp fastdir /usr/local/bin/
	sudo chmod +x /usr/local/bin/fastdir
	@echo "✅ Installed to /usr/local/bin/fastdir"

test:
	@echo "🧪 Running tests..."
	mix test

clean:
	@echo "🧹 Cleaning..."
	mix clean
	rm -f fastdir

