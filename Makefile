IMAGE_REPO=ghcr.io/radicldefense/rad-manual-approval

.PHONY: tidy
tidy:
	go mod tidy

.PHONY: build
build:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required"; \
		exit 1; \
	fi
	@echo "Building AMD64 image..."
	docker build --platform linux/amd64 -t $(IMAGE_REPO):$(VERSION)-amd64 .
	@echo "Building ARM64 image..."
	docker build --platform linux/arm64 -t $(IMAGE_REPO):$(VERSION)-arm64 .
	@echo "Pushing AMD64 image..."
	docker push $(IMAGE_REPO):$(VERSION)-amd64
	@echo "Pushing ARM64 image..."
	docker push $(IMAGE_REPO):$(VERSION)-arm64
	@echo "Creating multi-arch manifest..."
	docker manifest create $(IMAGE_REPO):$(VERSION) \
		--amend $(IMAGE_REPO):$(VERSION)-amd64 \
		--amend $(IMAGE_REPO):$(VERSION)-arm64
	@echo "Pushing multi-arch manifest..."
	docker manifest push $(IMAGE_REPO):$(VERSION)

.PHONY: build-local
build-local:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required"; \
		exit 1; \
	fi
	docker build --platform linux/amd64 -t $(IMAGE_REPO):$(VERSION) .

.PHONY: push
push:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required"; \
		exit 1; \
	fi
	@echo "Images are already pushed during build step"

.PHONY: test
test:
	go test -v .

.PHONY: lint
lint:
	docker run --rm -v $$(pwd):/app -w /app golangci/golangci-lint:v1.46.2 golangci-lint run -v
