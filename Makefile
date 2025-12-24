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
	@echo "Building and pushing AMD64 image..."
	@docker buildx build --platform linux/amd64 --provenance=false --sbom=false -t $(IMAGE_REPO):$(VERSION)-amd64 --push . || (echo "Failed to build/push AMD64 image" && exit 1)
	@echo "Building and pushing ARM64 image..."
	@docker buildx build --platform linux/arm64 --provenance=false --sbom=false -t $(IMAGE_REPO):$(VERSION)-arm64 --push . || (echo "Failed to build/push ARM64 image" && exit 1)
	@echo "Creating multi-arch manifest..."
	@docker buildx imagetools create -t $(IMAGE_REPO):$(VERSION) \
		$(IMAGE_REPO):$(VERSION)-amd64 \
		$(IMAGE_REPO):$(VERSION)-arm64 || (echo "Failed to create multi-arch manifest" && exit 1)
	@echo "Successfully built and pushed multi-arch image: $(IMAGE_REPO):$(VERSION)"

.PHONY: build-only
build-only:
	@echo "Building AMD64 image (no push) - verifying build works..."
	docker buildx build --platform linux/amd64 -t $(IMAGE_REPO):test-amd64 --load .
	@echo "Building ARM64 image (no push) - verifying cross-platform build works..."
	@TMPFILE=$$(mktemp) && \
	docker buildx build --platform linux/arm64 -t $(IMAGE_REPO):test-arm64 --output type=oci,dest=$$TMPFILE . && \
	rm -f $$TMPFILE && \
	echo "ARM64 build verified successfully"

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
