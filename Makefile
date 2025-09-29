.PHONY: build install test clean docker help

APP_NAME = fastdir
DOCKER_IMAGE = lgdev2002/fastdir
VERSION = 1.0.0

help:
	@echo "FastDir - Ultra Fast Directory Brute Forcer"
	@echo "Available commands:"
	@echo "  make build    - Build the application"
	@echo "  make install  - Install locally"
	@echo "  make test     - Run tests"
	@echo "  make docker   - Build Docker image"
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

docker:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(VERSION) .
	docker tag $(DOCKER_IMAGE):$(VERSION) $(DOCKER_IMAGE):latest
