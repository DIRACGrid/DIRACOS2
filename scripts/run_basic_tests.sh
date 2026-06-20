#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

IMAGE_NAME=$1
DIRACOS_INSTALLER=$2

exec docker run --rm --privileged -v "${PWD}":/diracos-repo "${IMAGE_NAME}" bash -c '
  set -euxo pipefail
  # Install as a non-root user with a read-only $HOME so that DIRACGrid/DIRACOS2#174
  # (installer failing on mkdir ~/.conda when $HOME is not writable) would be
  # reproduced here. Root ignores permission bits, so this check only works as
  # a real, unprivileged user.
  useradd -m -u 1001 tester
  workdir=$(mktemp -d)
  chown tester:tester "${workdir}"
  install_home="${workdir}/home"
  mkdir "${install_home}"
  chown tester:tester "${install_home}"
  chmod 500 "${install_home}"

  install_cmd="env HOME=\"${install_home}\" bash -c \"cd \\\"${workdir}\\\" && bash /diracos-repo/'"${DIRACOS_INSTALLER}"'\""
  if command -v runuser >/dev/null 2>&1; then
    runuser -u tester -- bash -c "${install_cmd}"
  elif command -v su >/dev/null 2>&1; then
    su -s /bin/bash tester -c "${install_cmd}"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -u tester bash -c "${install_cmd}"
  else
    echo "Neither runuser, su, nor sudo is available in the container" >&2
    exit 1
  fi

  # Restore normal permissions for the post-install test suite (singularity
  # user-namespace mapping cannot traverse tester-owned dirs).
  chown -R root:root "${workdir}"
  chmod 755 "${workdir}" "${install_home}"
  cd "${workdir}"
  source diracos/diracosrc
  pytest -v /diracos-repo/tests/test_import.py
  bash /diracos-repo/tests/test_cli.sh
'
