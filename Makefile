VERSION := $(shell git describe --tags --abbrev=0)
DOCKER_TAG := $(shell date +%Y%m%d)

# For consistency, the src dirs are named like the images they produce
IMAGES = ogp-panel ogp-agent

# Keep "stamps" around, recording that images were built. 
# You could keep them in e.g. a `.docker-buildstamps/*` dir, 
# but this example uses `*/.podman-build-flag`.
BUILDSTAMP_FILE = .podman-build-flag
BUILDSTAMPS = $(addsuffix /$(BUILDSTAMP_FILE),$(IMAGES))

.PHONY: all
all: $(BUILDSTAMPS)

# Pattern rule: let e.g. `a/.podman-build-flag` depend on changes to `a/*` (-but avoid circular dep)
%/$(BUILDSTAMP_FILE): % %/[!$(BUILDSTAMP_FILE)]*
	$(docker_build)

clean:
	@podman image rm -f diacreorg/$(IMAGES)
	rm -f $(BUILDSTAMPS)

# Turn `a/.podman-build-flag` back into `a`
define from_buildstamp
$(@:%/$(BUILDSTAMP_FILE)=%)
endef

# Self-explanatory
define docker_build
@echo "Building $(from_buildstamp) image with version: ${VERSION}-$(DOCKER_TAG)"
@echo "Using Docker tag: $(DOCKER_TAG)"
@echo "Building $(from_buildstamp) image..."
@echo "Building $(from_buildstamp) image with version: ${VERSION}-$(DOCKER_TAG)"
@podman build -t diacreorg/$(from_buildstamp):${VERSION}-$(DOCKER_TAG) $(from_buildstamp)
@podman tag diacreorg/$(from_buildstamp):${VERSION}-$(DOCKER_TAG) diacreorg/$(from_buildstamp):latest

touch $@
endef
