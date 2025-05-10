VERSION := $(shell git describe --tags --abbrev=0)
DOCKER_TAG := $(shell date +%Y%m%d)

.PHONY: ogp-panel ogp-agent
.DEFAULT_GOAL := all
all: ogp-panel ogp-agent

ogp-panel: Makefile ogp-panel/Containerfile ogp-panel/config.inc.php ogp-panel/vhost.conf
	@echo "Building ogp-panel image with version: ${VERSION}-$(DOCKER_TAG)"
	@echo "Using Docker tag: $(DOCKER_TAG)"
	@echo "Building ogp-panel image..."
	@echo "Building ogp-panel image with version: ${VERSION}-$(DOCKER_TAG)"
	@podman build -t diacreorg/ogp-panel:${VERSION}-$(DOCKER_TAG) ogp-panel
	@podman tag diacreorg/ogp-panel:${VERSION}-$(DOCKER_TAG) diacreorg/ogp-panel:latest

ogp-agent: Makefile ogp-agent/Containerfile ogp-agent/entrypoint.sh
	@podman build -t diacreorg/ogp-agent:${VERSION}-$(DOCKER_TAG) ogp-agent
	@podman tag diacreorg/ogp-agent:${VERSION}-$(DOCKER_TAG) diacreorg/ogp-agent:latest

release:
	podman build -t diacreorg/ogp-panel:${VERSION} ogp-panel
	podman tag diacreorg/ogp-panel:${VERSION} diacreorg/ogp-panel:latest
	podman push diacreorg/ogp-panel:${VERSION}
	podman push diacreorg/ogp-panel:latest
