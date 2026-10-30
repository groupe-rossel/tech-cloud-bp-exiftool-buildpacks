# ExifTool Buildpack

This Cloud Native Buildpack installs a standalone [ExifTool](https://exiftool.org/) binary on Linux amd64 (glibc).

It does **not** install Perl on the stack. The binary is built and published by this repository (PAR::Packer, amd64/glibc) and embeds its own runtime.

The packaging pipeline is adapted from [pulsejet/exiftool-bin](https://github.com/pulsejet/exiftool-bin) at commit [`a796daa`](https://github.com/pulsejet/exiftool-bin/commit/a796daa98a47505db132e031837692313481850a) (see [`docs/exiftool-bin-release.md`](docs/exiftool-bin-release.md)).

## Requirements

- Target: `linux` / `amd64` / **glibc** only (musl and aarch64 are out of scope for v1)
- CNB API `0.8`

## Version pin

ExifTool artefact version and SHA-256 are variables in `bin/build` (current pin: **13.59**).

Download URL:

```text
https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/<version>/exiftool-amd64-glibc
```

To bump ExifTool after a new binary release exists:

1. Copy the hash from the release asset `SHA256SUMS` (also in the release notes)
2. Update `EXIFTOOL_BIN_VERSION` and `EXIFTOOL_BIN_SHA256` in `bin/build`
3. Bump the buildpack `version` in `buildpack.toml`

## Binary release pipeline

Nightly cron + `workflow_dispatch` publish `exiftool-amd64-glibc` to this repo’s GitHub Releases.

Full documentation (CI jobs, local build, bootstrap, verification):

→ [`docs/exiftool-bin-release.md`](docs/exiftool-bin-release.md)

## Usage

Use this repository as a standalone custom buildpack. Detection always succeeds and ExifTool is always installed when the buildpack participates.

After the build, verify:

```sh
exiftool -ver
```

## Deployment

Increment the buildpack version in `buildpack.toml` whenever the artefact version, checksum, download URL, or layer environment configuration changes, so builders do not reuse a stale buildpack artefact.
