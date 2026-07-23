# Verifying Mazzite image signatures

Mazzite images are cosign-signed. The same key pair is used for the
UBlueOS and Mazzite images (one maintainer, one identity).

## Files in this repo

- `cosign.pub` — public key, safe to commit, used to verify signatures.

The corresponding private key (`cosign.key`) is **never** in this repo.
It lives in your local copy at the path you used when you generated the
pair (e.g. `/home/patrik/UBlueOS/cosign.key`).

## Verify an image tag

```
cosign verify --key cosign.pub ghcr.io/patrikhallgren/mazzite:stable
```

Expected output: a JSON object listing the image digest and signing
identity.

## Rotate the signing key

If you need to rotate (lost key, suspect compromise, want a fresh
identity):

```
COSIGN_PASSWORD="" cosign generate-key-pair
# Replace cosign.pub in this repo AND in UBlueOS
# Update SIGNING_SECRET in BOTH repos' GitHub Actions settings
# Re-run both repos' CI builds; old tags remain signed by the old key
```

Old tags are NOT re-signed. Downstream rebase users will need to either
trust the new key, or pin to a tag that was signed by the key they have.
