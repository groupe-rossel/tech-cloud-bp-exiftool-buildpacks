# ExifTool Buildpack

This Cloud Native Buildpack installs a standalone [ExifTool](https://exiftool.org/) binary on Linux amd64 (glibc).

It does **not** install Perl on the stack. The binary is built and published by this repository (PAR::Packer, amd64/glibc) and embeds its own runtime.

The packaging pipeline is adapted from [pulsejet/exiftool-bin](https://github.com/pulsejet/exiftool-bin) at commit [`a796daa`](https://github.com/pulsejet/exiftool-bin/commit/a796daa98a47505db132e031837692313481850a) (see [`docs/exiftool-bin-release.md`](docs/exiftool-bin-release.md)).

## Requirements

- Target: `linux` / `amd64` / **glibc** only (musl and aarch64 are out of scope for v1)
- CNB API `0.8`

## Artefact resolution

At build time, `bin/build` resolves a GitHub Release of this repository, then:

1. Downloads `SHA256SUMS` from that release
2. Reads the SHA-256 for `exiftool-amd64-glibc`
3. Downloads the binary and verifies the checksum (hard-fail on mismatch)
4. Installs it into a CNB layer with `cache = false` (re-download on every build)

### Optional: `BP_EXIFTOOL_MAJOR_VERSION`

| Valeur | Comportement |
|---|---|
| unset | dernière release (`/releases/latest`) |
| entier ≥ `13` | dernière release de cette majeure (`13.x` → max `13.*` via `sort -V`) |

Contraintes : entier uniquement (`^[0-9]+$`), valeur **≥ 13**. Sinon le build échoue. Si aucune release n’existe pour la majeure demandée, échec hard.

No full version/SHA pin in `bin/build`. New binary releases are picked up automatically on the next pack build (within the selected major, if set).

Download pattern (after resolution):

```text
https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/<version>/exiftool-amd64-glibc
https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/<version>/SHA256SUMS
```

## Binary release pipeline

Nightly cron + `workflow_dispatch` publish `exiftool-amd64-glibc` to this repo’s GitHub Releases.

Full documentation (CI jobs, local build, buildpack consumption, verification):

→ [`docs/exiftool-bin-release.md`](docs/exiftool-bin-release.md)

## Usage

Use this repository as a standalone custom buildpack. Detection succeeds on **linux / amd64 / glibc** only (writes a CNB plan providing `exiftool`); musl or other arches are skipped (`exit 100`). When detection passes, ExifTool is installed for build and launch.

After the build, verify:

```sh
exiftool -ver
```

## Deployment

Increment the buildpack version in `buildpack.toml` whenever the buildpack contract changes (layer env, detect/build behaviour, download/resolution logic), so builders do not reuse a stale buildpack artefact.
