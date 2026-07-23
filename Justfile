# Mazzite local build recipes
# Requires: podman, rpm-ostree (for rechunk)

# Set this to your image tag and registry for local builds.
IMAGE_NAME := "mazzite"
BASE_IMAGE := "ghcr.io/ublue-os/bazzite-nvidia:stable"

# Build the image without pushing. Runs as root because podman
# needs to manage the container's mount namespaces.
build:
    sudo podman build \
        --build-arg BASE_IMAGE={{BASE_IMAGE}} \
        --label="containers.bootc=1" \
        -t {{IMAGE_NAME}}:latest .

# Build and tag for a specific variant (e.g. stable).
build-variant VARIANT:
    sudo podman build \
        --build-arg BASE_IMAGE={{BASE_IMAGE}} \
        --label="containers.bootc=1" \
        -t {{IMAGE_NAME}}:{{VARIANT}} .

# Rechunk the built image for smaller delta updates.
rechunk:
    sudo podman run --rm --privileged \
        --pid=host --volume /var/lib/containers:/var/lib/containers \
        ghcr.io/ublue-os/ublue-update:latest \
        cli rechunk {{IMAGE_NAME}}:latest || true

# Run a shell inside the built image for debugging.
shell:
    sudo podman run --rm -it --entrypoint=/bin/bash {{IMAGE_NAME}}:latest

# Clean up local build artefacts.
clean:
    podman rmi -f {{IMAGE_NAME}}:latest 2>/dev/null || true
