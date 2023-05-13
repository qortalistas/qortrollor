#!/usr/bin/env bash

execute() {
  load_qystemd_lib
  test
}

# shellcheck disable=SC1090
load_qystemd_lib() {
  local operating_dir lib lib_name seek_dir prev_seek_dir
  operating_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  lib_name='qortrollor.lib.sh'
  seek_dir="${operating_dir}}"
  lib="${seek_dir}/${lib_name}"
  while [[ ! -f "${lib}" ]]; do
    prev_seek_dir="${seek_dir}"
    seek_dir="$(dirname "${seek_dir}")"
    if [[ "${seek_dir}" == "${prev_seek_dir}" ]]; then
      fail "Could not find ${lib_name}"
    fi
    lib="${seek_dir}/${lib_name}"
  done
  . "${lib}" '--habitize' '--showcall' || fail "Could not source ${lib}"
  qortrollor_load_manipulate_qystemd
}

fail() {
  echo "FAIL: $1"
  exit 1
}

execute
