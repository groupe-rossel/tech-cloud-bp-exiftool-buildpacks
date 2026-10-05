# ExifTool Buildpack

This Cloud Native Buildpack installs a standalone [ExifTool](https://exiftool.org/) binary on Linux amd64 (glibc).

It does **not** install Perl on the stack. The binary comes from [pulsejet/exiftool-bin](https://github.com/pulsejet/exiftool-bin) and embeds its own runtime.

## Requirements

- Target: `linux` / `amd64` / **glibc** only (musl and aarch64 are out of scope for v1)
- CNB API `0.8`

## Version pin

ExifTool artefact version and SHA-256 are variables in `bin/build` (initial pin: **13.59**).

To bump ExifTool:

1. Update `EXIFTOOL_BIN_VERSION` and `EXIFTOOL_BIN_SHA256` in `bin/build`
2. Bump the buildpack `version` in `buildpack.toml`

## Usage

Use this repository as a standalone custom buildpack. Detection always succeeds and ExifTool is always installed when the buildpack participates.

After the build, verify:

```sh
exiftool -ver
```

## Deployment

Increment the buildpack version in `buildpack.toml` whenever the artefact version, checksum, download URL, or layer environment configuration changes, so builders do not reuse a stale buildpack artefact.
