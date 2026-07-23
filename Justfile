# Local Mazzite build recipes
# Requires: bluebuild, podman, just

# Set this to your image tag and registry for local builds.
IMAGE_NAME := "mazzite"
IMAGE_REGISTRY := "ghcr.io/patrikhallgren"
IMAGE_TAG := "stable"

# Build the image without pushing.
build:
    sudo bluebuild build --recipe recipes/recipe.yml

# Build and tag locally for rebase testing.
build-local:
    sudo bluebuild build --recipe recipes/recipe.yml \
        --tag {{IMAGE_REGISTRY}}/{{IMAGE_NAME}}:{{IMAGE_TAG}}

# Validate the recipe without actually building.
lint:
    bluebuild lint recipes/recipe.yml

# Remove the local build artefacts.
clean:
    podman rmi -f {{IMAGE_REGISTRY}}/{{IMAGE_NAME}}:{{IMAGE_TAG}} 2>/dev/null || true
