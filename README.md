# DIRACOS2

Python 3 DIRACOS installer built using [conda constructor](https://github.com/conda/constructor) and [conda-forge](https://conda-forge.org/).

## Table of contents

* [Installing DIRACOS2](#installing-diracos2)
* [Advanced documentation](#advanced-documentation)
    * [Building the installer](#building-the-installer)
    * [Testing the installer](#testing-the-installer)
    * [Making a release](#making-a-release)
    * [Building customised packages](#building-customised-packages)
    * [Miscellaneous remarks](#miscellaneous-remarks)
* [Troubleshooting](#troubleshooting)
    * [Duplicate files](#duplicate-files)

## Installing DIRACOS2

These instructions will install the latest release of DIRACOS in a folder named `diracos`. Installers are published for the following platforms:

* `DIRACOS-Linux-x86_64.sh`
* `DIRACOS-Linux-aarch64.sh`
* `DIRACOS-Darwin-x86_64.sh` (client-only)
* `DIRACOS-Darwin-arm64.sh` (client-only)

To install a specific version, replace `/latest/download/` in the URL with `/download/<version>/`. The full list of releases is available on the [releases page](https://github.com/DIRACGrid/DIRACOS2/releases).

```bash
curl -LO https://github.com/DIRACGrid/DIRACOS2/releases/latest/download/DIRACOS-Linux-x86_64.sh
bash DIRACOS-Linux-x86_64.sh
```

It can then be activated in a similar way to version 1 of DIRACOS, by calling `source "$PWD/diracos/diracosrc"`.
Further usage instructions are shown after installation.

## Advanced documentation

### Building the installer

The DIRACOS installer is a self-extracting shell script generated using [conda constructor](https://github.com/conda/constructor). The build environment is managed with [pixi](https://pixi.sh):

```bash
pixi install
pixi run build-installer
```

This produces `DIRACOS-<version>-<platform>.sh` in the current directory, targeting the host platform. Cross-platform builds are handled in CI, where each of `linux-64`, `linux-aarch64`, `osx-64`, and `osx-arm64` is built on a matching runner. The `CONDA_OVERRIDE_GLIBC` / `CONDA_OVERRIDE_OSX` values for each target are set in `pixi.toml`.

The packages included are defined in `construct.yaml`; see the [upstream documentation](https://github.com/conda/constructor/blob/master/CONSTRUCT.md) for more details. For faster local iteration, `transmute_file_type` in `construct.yaml` can be disabled at the cost of a larger installer.

### Testing the installer

Basic tests of the installer can be run against an arbitrary docker image with:

```bash
scripts/run_basic_tests.sh DOCKER_IMAGE DIRACOS_INSTALLER_FILENAME
```

### Making a release

To ensure reproducibility, releases are made from build artifacts of previous pipelines and tagged via GitHub Actions by triggering the [Create release](https://github.com/DIRACGrid/DIRACOS2/actions/workflows/release.yaml?query=workflow%3A%22Create+release%22) workflow. This workflow runs [`scripts/make_release.py`](https://github.com/DIRACGrid/DIRACOS2/blob/main/scripts/make_release.py) and has the following optional parameters:

* **Run ID**: The GitHub Actions workflow run ID whose artifacts will be released. If not given, defaults to the most recent build of the `main` branch.
* **Version number**: A [PEP-440](https://www.python.org/dev/peps/pep-0440/) compliant version number. If not given, defaults to the `version` field in `construct.yaml` rounded to the next full release (e.g. `2.4a5` becomes `2.4`, `2.1` stays `2.1`). Passing an explicit pre-release marks the release as a pre-release in GitHub and does not affect the `latest` alias.

The `version` field in `construct.yaml` is rolling bookkeeping rather than something that is hand-edited per release: after each release, a commit is pushed to `main` bumping it to the next alpha (skipped if that would be a downgrade). The binary installer's embedded version is rewritten at release time by `make_release.py`.

If the release process fails, a draft release may be left in GitHub. After the issue has been fixed it can be safely deleted before rerunning the CI.

### Building customised packages

See [`management/conda-recipes`](https://github.com/DIRACGrid/management/tree/master/conda-recipes).

### Miscellaneous remarks

DIRACOS2 is a smaller wrapper around [conda constructor](https://github.com/conda/constructor) which generates a self-extracting installer that is suitable for DIRAC's needs based on packages which are distributed by [conda-forge](https://conda-forge.org/). As such, most components are documented by their respective projects. The following is a list of remarks that are specific DIRACOS2:

* The build-and-test workflow runs on every push event as well as once per day. GitHub Actions limitations will cause the nightly build to be disabled if there is no activity in the repository for 60 days. If this happens, it can be easily re-enabled by pushing an empty commit to `main`.
* The DIRACOS installer follows the common pattern of being a shell script that exits followed by an arbitrary binary blob. In principle it is possible to create other kinds of installer with `constructor`, however these are not deemed to be of interest at the current time.
* Similarly to the original DIRACOS, releases are made by assigning a version number to a previous CI build. As `constructor` embeds the version number into the installer at build time, this means the version has to be edited in the binary artifact. Fortunately this is only embedded in the shell script at the start of the file, so it's a relatively simple string manipulation, performed in the `main()` function of [`scripts/make_release.py`](https://github.com/DIRACGrid/DIRACOS2/blob/main/scripts/make_release.py). As this is not an officially supported feature of constructor it is prone to changing at any time.

## Troubleshooting

This section contains a list of know issues that can occur.

### Duplicate files

This error is of the form:

```
File 'include/event.h' found in multiple packages: libevent-2.1.10-hcdb4288_2.tar.bz2, libev-4.33-h516909a_0.tar.bz2
```

When this happens, the offending packages should be fixed upstream in conda-forge. As a temporary workaround, the `ignore_duplicate_files` key in `construct.yaml` can be changed to `true`.
