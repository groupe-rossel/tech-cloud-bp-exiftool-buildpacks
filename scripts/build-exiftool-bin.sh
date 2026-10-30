#!/usr/bin/env bash
# Build a standalone amd64/glibc ExifTool binary (PAR::Packer).
# Adapted from pulsejet/exiftool-bin @ a796daa98a47505db132e031837692313481850a
#   https://github.com/pulsejet/exiftool-bin/commit/a796daa98a47505db132e031837692313481850a
# Sole code source: GitHub tags https://github.com/exiftool/exiftool/tags
# Does not touch the CNB bin/detect or bin/build paths.
set -euo pipefail

: "${EXIFTOOL_VERSION:?EXIFTOOL_VERSION is required (e.g. 13.59)}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
DIST_DIR="${ROOT_DIR}/dist"
ASSET_NAME="exiftool-amd64-glibc"

GITHUB_TAGS_PAGE="https://github.com/exiftool/exiftool/tags"
GITHUB_ARCHIVE_URL="https://github.com/exiftool/exiftool/archive/refs/tags/${EXIFTOOL_VERSION}.tar.gz"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "==> Building ExifTool ${EXIFTOOL_VERSION} (${ASSET_NAME})"
echo "==> Code source: ${GITHUB_TAGS_PAGE} (tag ${EXIFTOOL_VERSION})"
mkdir -p "${DIST_DIR}" "${WORK_DIR}/src"

echo "==> Downloading GitHub tag archive"
if ! curl -fsSL --retry 3 --retry-connrefused --connect-timeout 15 \
  -o "${WORK_DIR}/github.tar.gz" "${GITHUB_ARCHIVE_URL}"; then
  echo "ERROR: Failed to download tag ${EXIFTOOL_VERSION} from ${GITHUB_TAGS_PAGE}"
  echo "  URL: ${GITHUB_ARCHIVE_URL}"
  exit 1
fi

echo "==> Extracting archive"
tar -xzf "${WORK_DIR}/github.tar.gz" -C "${WORK_DIR}/src"

SRC="$(find "${WORK_DIR}/src" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "${SRC}" ]]; then
  echo "ERROR: Failed to locate extracted source tree"
  exit 1
fi

if [[ ! -f "${SRC}/exiftool" ]]; then
  echo "ERROR: exiftool script missing from GitHub tag ${EXIFTOOL_VERSION}"
  exit 1
fi
if [[ ! -d "${SRC}/lib" ]]; then
  echo "ERROR: lib/ directory missing from GitHub tag ${EXIFTOOL_VERSION}"
  exit 1
fi
if [[ ! -f "${SRC}/pp_build_exe.args" ]]; then
  echo "ERROR: pp_build_exe.args missing from GitHub source (required for PAR build)"
  exit 1
fi

echo "==> Installing build dependencies (cpanm / PAR::Packer)"
curl -fsSL https://cpanmin.us | perl - --self-upgrade
cpanm --notest Archive::Zip PAR PAR::Packer IO::String

BUILD_SRC="${WORK_DIR}/build-src"
cp -a "${SRC}" "${BUILD_SRC}"
cd "${BUILD_SRC}"
rm -rf windows_exiftool html t

echo "==> Running pp (PAR::Packer)"
# Word-splitting of pp args is intentional (same pattern as pulsejet/exiftool-bin).
# shellcheck disable=SC2046
pp $(awk '!/^#/ && !/Win32|Brotli/' pp_build_exe.args | tr '\n' ' ')
if [[ ! -f exiftool.exe ]]; then
  echo "ERROR: pp did not produce exiftool.exe"
  exit 1
fi

install -m 0755 exiftool.exe "${DIST_DIR}/${ASSET_NAME}"

echo "==> Smoke test"
INSTALLED_VERSION="$("${DIST_DIR}/${ASSET_NAME}" -ver)"
if [[ "${INSTALLED_VERSION}" != "${EXIFTOOL_VERSION}" ]]; then
  echo "ERROR: Packed binary version mismatch."
  echo "  expected: ${EXIFTOOL_VERSION}"
  echo "  actual:   ${INSTALLED_VERSION}"
  exit 1
fi

(
  cd "${DIST_DIR}"
  sha256sum "${ASSET_NAME}" > SHA256SUMS
)

echo "==> Built ${DIST_DIR}/${ASSET_NAME}"
echo "==> $(cat "${DIST_DIR}/SHA256SUMS")"
echo "==> Done"
