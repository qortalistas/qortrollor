#!/usr/bin/env bash

execute() {
  # shellcheck disable=SC1090
  . "${QORTROLLOR_LIB}" # '--habitize'
  #  qortrollor_load_manipulate_qystemd
  qortrollor_load_execute_qystemd_lib
  qystemd_execute "$@"

  #  qortrollor_load_manipulate_qystemd
  #  systemd_execute "$@"
  #  exec "${QYSTEMD_RUN_FILE}" "$@"
  #  local instrux
  #  instrux=$1
  #  "execute_${instrux}" "$@"
}

execute_start() {
  echo execute_start
  echo 'params:' "$@"
  echo "1 QYSTEMD_RUN_DIR: ${QYSTEMD_RUN_DIR}"
  load_config
  export_config
  echo "2 QYSTEMD_RUN_DIR: ${QYSTEMD_RUN_DIR}"
  systemd-notify --ready
  #  sleep 0.2
  #  systemd-notify --status='READY EDDIE!'
  #  sleep 1

}

execute_stop() {
  echo execute_stop
  echo 'params:' "$@"
  #  systemd-notify --status='STOPPED EDDIE!'
}

#execute() {
#  load_config
#  export_config
#  exec "${PYTHEETOR}" "${CONFILE}" "$@"
#}
#
load_config() {
  #  CONFILE=".env.${BASH_SOURCE[0]%_executor.sh}"
  CONFILE="${BASH_SOURCE[0]%_executor.sh}.conf"
  echo "Load CONFILE: ${CONFILE}"
  # shellcheck disable=SC1090
  . "${CONFILE}" && return 0
  echo "${BASH_SOURCE[0]}; Failed to load lib: ${CONFILE}"
  exit 1
}

export_config() {
  declare -a lines
  while IFS= read -r line; do
    lines+=("$line")
  done <"${CONFILE}"

  for line in "${lines[@]}"; do
    # skip comments
    [[ "$line" =~ ^#.*$ ]] && continue
    # skip empty lines
    [[ -z "$line" ]] && continue
    # skip lines that don't have an "="
    [[ "$line" =~ ^[^=]*$ ]] && continue
    IFS='=' read -r key rest <<<"$line"
    # skip if no key.
    if [[ -z "$key" ]]; then
      echo "BAD line: $line"
      continue
    fi
    echo " ------ key: $key: ${!key}"
    # shellcheck disable=SC2163
    export "$key"
  done
}
################################################################################
#_execute() {
#  #  CONFILE=$1
#  CUP_NAME=$1
#  load_lib
#  defunc "$@"
#  #  load_config "$@"
#  echo "CUP_NAME: ${CUP_NAME}"
#  #  echo "CUPXECUTOR: ${CUPXECUTOR}"
#  #  if [[ -f "${CUPXECUTOR}" ]]; then
#  #    echo "CUP_EXE exists: ${CUPXECUTOR}"
#  #  else
#  #    echo "CUP_EXE does not exist: ${CUPXECUTOR}"
#  #  fi
#  #  #  #  debug 'post load_lib'
#  #  #  #  debug "QYSTEMD_PROJECT_DIR: $QYSTEMD_PROJECT_DIR"
#  #  #  activenvate
#  #  #  run_pythee "$@"
#}

#_load_lib() {
#  #  echo "Load lib: BASH_SOURCE: ${BASH_SOURCE[0]}"
#  #  echo "Load lib: arg 0: $0"
#
#  REAL_SOURCE="${BASH_SOURCE[0]}"
#  if [[ -L "${REAL_SOURCE}" ]]; then
#    echo "Load lib: ${REAL_SOURCE} is a symlink"
#    REAL_SOURCE="$(readlink "${REAL_SOURCE}")"
#    echo "Load lib: REAL_SOURCE: ${REAL_SOURCE}"
#  fi
#
#  lib="$(realpath "$(dirname "${REAL_SOURCE}")/../components/qystemd.lib.sh")"
#  # shellcheck disable=SC1090
#  . "$lib" && return 0
#  echo "Failed to load lib: $lib"
#  exit 1
#}

#_load_config() {
#  CONFILE=$1
#  echo "Load CONFILE: ${CONFILE}"
#  # shellcheck disable=SC1090
#  . "${CONFILE}" && return 0
#  echo "Failed to load lib: ${CONFILE}"
#  exit 1
#}

execute "$@"
