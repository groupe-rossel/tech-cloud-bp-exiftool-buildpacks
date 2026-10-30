# CI de compilation et release du binaire ExifTool

Ce dépôt publie un binaire autonome `exiftool-amd64-glibc` (Perl embarqué via PAR::Packer) en **GitHub Releases**. Le buildpack CNB (`bin/build`) télécharge ensuite cet asset.

## Provenance

La mécanique de compilation PAR (script `pp` / `pp_build_exe.args`, packing du runtime Perl) est une **reprise adaptée** de [pulsejet/exiftool-bin](https://github.com/pulsejet/exiftool-bin), figée sur le commit :

[`a796daa98a47505db132e031837692313481850a`](https://github.com/pulsejet/exiftool-bin/commit/a796daa98a47505db132e031837692313481850a)

Différences principales par rapport à ce dépôt tiers :

- une seule cible : `amd64` / glibc (pas musl, pas aarch64, pas `eperl`)
- source code : tags [exiftool/exiftool](https://github.com/exiftool/exiftool/tags) uniquement
- publication des assets dans **ce** dépôt (GitHub Releases), consommés par `bin/build`

## Objectif

| Élément | Valeur |
|---|---|
| Asset | `exiftool-amd64-glibc` |
| Checksums | `SHA256SUMS` (même release) |
| Tag de release | numéro ExifTool (ex. `13.59`, sans préfixe `v`) |
| Cible | `linux` / `amd64` / glibc (Ubuntu 24.04) |
| Source code | tags [exiftool/exiftool](https://github.com/exiftool/exiftool/tags) uniquement |

URL de téléchargement :

```text
https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/<version>/exiftool-amd64-glibc
```

## Fichiers

| Chemin | Rôle |
|---|---|
| [`.github/workflows/exiftool-bin-release.yaml`](../.github/workflows/exiftool-bin-release.yaml) | CI : résolution de version, build, publication |
| [`scripts/build-exiftool-bin.sh`](../scripts/build-exiftool-bin.sh) | Compilation PAR + smoke test + `SHA256SUMS` |
| [`bin/build`](../bin/build) | Consommation CNB (download + vérif SHA-256) |

Les sorties locales vont dans `dist/` (gitignoré) ; elles ne font pas partie du layout CNB sous `bin/`.

## Déclencheurs

Workflow `exiftool-bin-release` :

1. **Cron** : `0 3 * * *` (03:00 UTC chaque nuit)
2. **Manuel** : `workflow_dispatch` avec input optionnel `version`
   - renseigné → build cette version
   - vide → dernier tag GitHub de `exiftool/exiftool` via `gh api`

Permissions : `contents: write` (création de release + upload d’assets).

## Pipeline CI (3 jobs)

```text
prepare ──► build (si release absente) ──► release
```

### 1. `prepare` (runner host `ubuntu-latest`)

- Résout `VERSION` (input ou latest tag `exiftool/exiftool`)
- Valide le format `N.N`
- Si `gh release view "$VERSION"` réussit → `exists=true` → **skip** des jobs suivants (idempotence)

### 2. `build` (container `ubuntu:24.04`)

- Installe les deps apt (perl, gcc, curl, …)
- Checkout du dépôt
- Exécute `EXIFTOOL_VERSION=$VERSION bash scripts/build-exiftool-bin.sh`
- Upload artifact Actions `exiftool-amd64-glibc` (`dist/exiftool-amd64-glibc` + `dist/SHA256SUMS`, rétention 7 jours)

Le container Ubuntu 24.04 fixe la glibc du binaire : portable vers des images Docker Ubuntu 24 et 26 ; pas garanti sur des bases plus anciennes que 24.

### 3. `release` (runner host `ubuntu-latest`)

- Télécharge l’artifact
- Vérifie `sha256sum -c SHA256SUMS`
- Crée la GitHub Release `$VERSION` avec les deux assets et des notes contenant le SHA-256

## Compilation locale (`scripts/build-exiftool-bin.sh`)

Prérequis : Perl, gcc/make, réseau (cpanm + download du tag).

```sh
export EXIFTOOL_VERSION=13.59   # obligatoire
bash scripts/build-exiftool-bin.sh
```

Étapes du script :

1. Télécharge `https://github.com/exiftool/exiftool/archive/refs/tags/${EXIFTOOL_VERSION}.tar.gz`
2. Vérifie la présence de `exiftool`, `lib/`, `pp_build_exe.args`
3. Installe via cpanm : `Archive::Zip`, `PAR`, `PAR::Packer`, `IO::String`
4. Lance `pp` avec les args de `pp_build_exe.args` (hors modules Win32/Brotli)
5. Installe le résultat sous `dist/exiftool-amd64-glibc`
6. Smoke : `./dist/exiftool-amd64-glibc -ver` doit égaler `$EXIFTOOL_VERSION`
7. Écrit `dist/SHA256SUMS`

Le script ne modifie jamais `bin/detect` / `bin/build`.

## Bootstrap / bump du pin buildpack

Après la **première** release réussie sur ce dépôt :

1. Actions → **exiftool-bin-release** → Run workflow (ex. `13.59` ou `13.60`)
2. Copier le hash depuis l’asset `SHA256SUMS` (ou les notes de release)
3. Mettre à jour dans `bin/build` :
   - `EXIFTOOL_BIN_VERSION`
   - `EXIFTOOL_BIN_SHA256`
4. Bumper `version` dans `buildpack.toml`

Tant que la release n’existe pas ou que le SHA ne correspond pas au binaire Rossel, un `pack build` qui consomme ce pin échouera au download ou au checksum.

## Vérification manuelle d’un asset publié

```sh
VERSION=13.59
curl -fsSL -O \
  "https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/${VERSION}/exiftool-amd64-glibc"
curl -fsSL -O \
  "https://github.com/groupe-rossel/tech-cloud-bp-exiftool-buildpacks/releases/download/${VERSION}/SHA256SUMS"
sha256sum -c SHA256SUMS
chmod +x exiftool-amd64-glibc
./exiftool-amd64-glibc -ver
```
