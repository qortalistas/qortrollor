#!/usr/bin/env bash

execute() {
  load_qystemd_lib
  develop
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

load_qystemd_lib_simple() {
  local operating_dir lib
  operating_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  lib="$(dirname "${operating_dir}")/qortrollor.lib.sh"
  # shellcheck disable=SC1090
  . "${lib}" '--habitize' '--showcall' || fail "Could not source ${lib}"
  qortrollor_load_manipulate_qystemd
}

load_up_lib() {
  local operating_dir lib
  operating_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  up_dir="$(dirname "${operating_dir}")"
  lib="${up_dir}/qortrollor.lib.sh"
  [[ -f "${lib}" ]] || lib="${operating_dir}/qortrollor.lib.sh"
  [[ -f "${lib}" ]] || lib="${operating_dir}/lode/qortrollor.lib.sh"
  [[ -f "${lib}" ]] || lib="${operating_dir}/qortrollor/lode/qortrollor.lib.sh"
  # shellcheck disable=SC1090
  . "${lib}" '--habitize' '--showcall' || fail "Could not source ${lib}"
  ####
  #  lib="${operating_dir}/qystemd.lib.sh"
  #  . "${lib}"  || fail "Could not source ${lib}"
}

fail() {
  echo "FAIL: $1"
  exit 1
}

execute
