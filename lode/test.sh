#!/usr/bin/env bash

execute() {
#  echo 'test_qortrollor'
  load_lib
  test
}

load_lib() {
  local operating_dir lib
  operating_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
  lib="${operating_dir}/qortrollor.lib.sh"
  [[ -f "${lib}" ]] || lib="${operating_dir}/lode/qortrollor.lib.sh"
  [[ -f "${lib}" ]] || lib="${operating_dir}/qortrollor/lode/qortrollor.lib.sh"
  # shellcheck disable=SC1090
  . "${lib}" '--habitize' '--showcall' || fail "Could not source ${lib}"
}

fail() {
  echo "FAIL: $1"
  exit 1
}

execute
#
