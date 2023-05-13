# region initialize
qystemd_initialize() {
  #  debug_func
  init_vars
}

init_vars() {
  QYSTEMD_NAME='qystemd'
  #  operating_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
  #  QYSTEMD_DIR="${QYSTEMD_DIR:-"${operating_dir}"}"
  #  [[ -n "${QYSTEMD_DIR}" ]] || QYSTEMD_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

  init_demo_run() {
    QYSTEMD_RUN_DIR="${QYSTEMD_DIR}/run_dummy"
    QYSTEMD_RUN_FILE="${QYSTEMD_RUN_DIR}/executee_pid.sh"
    QYSTEMD_PID_FILE="${QYSTEMD_RUN_DIR}/run.pid"
  }

  init_real_run() {
    QYSTEMD_RUN_DIR="${Q_HABITAT_DIR}"
    QYSTEMD_RUN_FILE="${QYSTEMD_DIR}/qystemd_executor.sh"
    QYSTEMD_PID_FILE="${QYSTEMD_RUN_DIR}/${Q_HABITAT_PID_FILENAME}"
    QYSTEMD_RUNLOG_FILE="${QYSTEMD_RUN_DIR}/${Q_HABITAT_RUNLOG_FILENAME}"
  }

  if [[ -n "${QYSTEMD_DIR}" ]]; then
    QYSTEMD_LIB_DIR="${QYSTEMD_DIR}"
    #    init_demo_run
    init_real_run
    #    QYSTEMD_RUN_DIR="${Q_HABITAT_DIR}"
    QYSTEMD_LOGS_DIR="${QORTROLLED_LOG_DIR}"
    QYSTEMD_PROJECT_DIR="${QYSTEMD_DIR}"
    QYSTEMD_SERVICE_DIR="${QYSTEMD_DIR}"
    #  QYSTEMD_LOGS_DIR="${QORTROLLED_LOG_DIR}/${QYSTEMD_NAME}"
  else
    ## hypothetical implementation:
    fail 'hypothetical implementation'
    QYSTEMD_LIB_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
    QYSTEMD_PROJECT_DIR="$(realpath "$(dirname "$0")"/../..)"
    QYSTEMD_PROJECT_DIR="$(realpath "$(dirname "$0")"/../..)"
    QYSTEMD_SERVICE_DIR="${QYSTEMD_PROJECT_DIR}/systemd"
    QYSTEMD_LOGS_DIR="${QYSTEMD_PROJECT_DIR}/logs"
  fi
  QYSTEMD_LOG_FILE="${QYSTEMD_LOGS_DIR}/${QYSTEMD_NAME}.log"
  QYSTEMD_BOOT_FILE="/tmp/${QYSTEMD_NAME}.boot"

  # Switch between system and user mode:
  #    QYSTEMD_SYSTEMD_MODE='system'
  QYSTEMD_SYSTEMD_MODE='user'
  if is_user_root; then
    QYSTEMD_SYSTEMD_MODE='system'
    debug "Running as root, switching QYSTEMD_SYSTEMD_MODE to: ${QYSTEMD_SYSTEMD_MODE}"
  fi
  if systemd_mode_is_user; then
    SYSTEM_CTL="$(which systemctl) --user "
    JOURNAL_CTL="$(which journalctl) --user "
  else
    SYSTEM_CTL="sudo $(which systemctl) "
    JOURNAL_CTL="sudo $(which journalctl) "
  fi
  #  show_vars
  #  debug_vars QYSTEMD_NAME QYSTEMD_LIB_DIR QYSTEMD_PROJECT_DIR QYSTEMD_SERVICE_DIR QYSTEMD_LOGS_DIR QYSTEMD_LOG_FILE QYSTEMD_BOOT_FILE QYSTEMD_SYSTEMD_MODE SYSTEM_CTL JOURNAL_CTL
}
# endregion initialize

# region develop
develop() {
  debug_func

  if [[ -d "$(get_config_dir)" ]]; then
    #    debug "Config dir exists: $(get_config_dir)"
    #    messagize "DESTROY"
    qystemd_uninstall
    #    erase_config_dir
  else
    #    debug "Config dir does not exist: $(get_config_dir)"
    #    messagize "CREATE"
    #    create_config_files
    qystemd_install
  fi

  createrase() {
    #  ls -ld "$(get_config_dir)"
    #  ls -lAh "$(get_config_dir)"
    create_config_files
    #    ls -ld "$(get_config_dir)"
    #    ls -lAh "$(get_config_dir)"

    echo
    cat "$(get_config_file 'env')"
    qystemd_install
    ####
    qystemd_uninstall
    erase_config_dir
    #  ls -ld "$(get_config_dir)"
    #  ls -lAh "$(get_config_dir)"
  }

  #  createrase
  #  create_config_files
}

qystemd_install() {
  debug_func
  messagize "QYSTEMD INSTALL"
  is_qortrollor_installed || fail 'Qortrollor is not installed.'
  if systemd_mode_is_user; then
    #    messagize "QYSTEMD INSTALL: USER MODE"
    messagize "Consider running: sudo loginctl enable-linger ${USER}"
    messagize "See readme 'Qystemd' for more info."
  fi
  create_config_files
  #  get_unit_name
  systemd__install_unit "$(get_unit_name)"
  systemd_enable_unit "$(get_unit_name)"
  ${SYSTEM_CTL} daemon-reload
  qystemd_habitastallation install
}

qystemd_uninstall() {
  debug_func
  messagize "QYSTEMD UNINSTALL"
  systemd_disable_unit "$(get_unit_name)"
  #  systemd__uninstall_unit "$(get_unit_name)"
  ${SYSTEM_CTL} daemon-reload
  erase_config_dir
  qystemd_habitastallation uninstall
}

qystemd_start() {
  debug_func
  messagize "START"
  systemd_start_service
}

qystemd_stop() {
  debug_func
  messagize "STOP"
  systemd_stop_service
}

qystemd_habitastallation() {
  #  debug_func
  local stalling origin_dir destin_dir origin_file destin_file source_postfix target_postfix transition
  stalling="$1"
  #  messagize "qystemd_habitastallation: ${stalling}"

  if [[ "${stalling}" == 'install' ]]; then
    origin_dir="${QYSTEMD_DIR}"
    destin_dir="${Q_HABITAT_DIR}"
  else
    origin_dir="${Q_HABITAT_DIR}"
  fi

  source_postfix='_qystemd.sh'
  target_postfix='_qortrollor_systemd.sh'
  for transition in 'start' 'stop'; do
    if [[ "${stalling}" == 'install' ]]; then
      origin_file="${origin_dir}/${transition}${source_postfix}"
      destin_file="${destin_dir}/${transition}${target_postfix}"
      cp "${origin_file}" "${destin_file}" || error "Unable to copy ${origin_file} to ${destin_file}"
    else
      origin_file="${origin_dir}/${transition}${target_postfix}"
      if [[ -f ${origin_file} ]]; then
        if [[ -z ${bu_now_dir} ]]; then
          bu_now_dir="$(get_uninstall_now_dir)"
          [[ -d ${bu_now_dir} ]] || mkdir -p "${bu_now_dir}" || error "Unable to create ${bu_now_dir}"
          destin_dir="${bu_now_dir}"
        fi
        destin_file="${destin_dir}/${transition}${target_postfix}"
        mv "${origin_file}" "${destin_file}" || error "Unable to move ${origin_file} to ${destin_file}"
      fi
    fi
    #    debug_vars origin_file destin_file
  done
}

systemctl_command() {
  debug_func
  debug "${SYSTEM_CTL}" "$@"
  ${SYSTEM_CTL} "$@"
}

#systemctl_command() {
#  local quiet
#  quiet=false
#
#  is_systemctl_noisy() {
#    [[ "${quiet}" == 'false' ]]
#  }
#
#  if [[ $1 == '--quiet' ]]; then
#    shift
#    quiet=true
#  fi
#
#  debug_func
#
#  #  if is_systemctl_noisy; then
#  debug "${SYSTEM_CTL}" "$@"
#  #  fi
#
#  ${SYSTEM_CTL} "$@"
#}

systemd_start_service() {
  systemctl_command start "$(get_unit_name)"
  #  ${SYSTEM_CTL} start "$(get_unit_name)"
}

systemd_stop_service() {
  systemctl_command stop "$(get_unit_name)"
  #  ${SYSTEM_CTL} stop "$(get_unit_name)"
  #  #  local name
  #  #  name="$(get_unit_name)"
  #  #  #  defunc "${name}"
  #  #  ${SYSTEM_CTL} stop "${name}"
}

systemd__install_unit() {
  debug_func
  local name file
  name="$1"
  if systemd_exists_unit "${name}"; then
    systemd__uninstall_unit "${name}"
  fi
  file="$(systemd_origin_file "${name}")"
  systemctl_command link "${file}"
  #  ${SYSTEM_CTL} link "${file}"
  #  #  txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"
  #  #  line1="$(echo "$txt" | head -n 1)"
  #  #  debug "${line1}"
}

systemd__uninstall_unit() {
  debug_func
  local name
  name="$1"
  if systemd_exists_unit "${name}"; then
    systemctl_command disable "${name}"
    #    ${SYSTEM_CTL} disable "${name}"
  else
    debug "No unit file for: ${name}"
  fi
}

systemd_origin_file() {
  local name file
  name="$1"
  #  file="${QYSTEMD_SERVICE_DIR}/${name}"
  file="${QYSTEMD_SERVICE_DIR}/${name}"
  echo "${file}"
}

systemd_enable_unit() {
  debug_func
  local name
  name="$1"
  systemctl_command enable "${name}"
  #  ${SYSTEM_CTL} enable "${name}"
}

systemd_disable_unit() {
  debug_func
  local name
  name="$1"
  systemctl_command disable "${name}"
  #  #  if [[ "${unit_type}" == 'timer' ]]; then
  #  #    ${SYSTEM_CTL} stop "${name}"
  #  #    ${SYSTEM_CTL} clean --what=state "${name}"
  #  #  fi
  #  ${SYSTEM_CTL} disable "${name}"
}

get_systemd_unit_file() {
  debug_func
  local name
  name="$1"
  local path

  #  if txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"; then
  if txt="$(${SYSTEM_CTL} cat "${name}" 2>/dev/null)"; then
    #    echo "txt: $txt"
    line1="$(echo "$txt" | head -n 1)"
    path="${line1:2}"
    echo "$path" # YES ECHO HERE!
  else
    error "Failed to get unit file for: $name"
    return 1
  fi
}

systemd_exists_unit() {
  #  debug_func
  local name path
  name="$1"
  if path="$(get_systemd_unit_file "${name}")"; then
    if [ -f "$path" ]; then
      debug "${path} exists"
      return 0
    fi
  fi
  return 1
}

get_unit_name() {
  local unit_type name
  unit_type='service'
  name="qortrollor.${unit_type}"
  #  name="${QYSTEMD_NAME}.${unit_type}"
  echo "${name}"

  #  unit_type="$1"
  #  #  name="${QYSTEMD_NAME}@"
  #  name="${QYSTEMD_CUP_NAME}@"
  #  if [[ $2 != 'template' ]]; then
  #    name="${name}${QYSTEMD_INSTANCE_NAME}"
  #  fi
  #  name="${name}.${unit_type}"
  #  echo "${name}"
}

create_config_files() {
  debug_func
  mkdir -p "$(get_config_dir)"
  QYSTEMD_EXECUTOR_ORIGIN_FILE="${QYSTEMD_LIB_DIR}/qystemd_executor.sh"
  #  QYSTEMD_EXECUTOR_DESTIN_FILE="$(get_config_dir)/qystemd_executor.sh"
  QYSTEMD_EXECUTOR_DESTIN_FILE="$(get_config_file 'exe')"
  [[ -f "${QYSTEMD_EXECUTOR_DESTIN_FILE}" ]] &&
    erase_fs_path "${QYSTEMD_EXECUTOR_DESTIN_FILE}"
  ln -s "${QYSTEMD_EXECUTOR_ORIGIN_FILE}" "${QYSTEMD_EXECUTOR_DESTIN_FILE}"

  #  QYSTEMD_RUN_DIR="${Q_HABITAT_DIR}"
  #  QYSTEMD_PID_FILE="${QYSTEMD_RUN_DIR}/run.pid"

  cat <<-EOF >"$(get_config_file 'env')"
## qystemd config file for systemd unit.
QORTROLLOR_LIB="${QORTROLLOR_LIB}"
QYSTEMD_RUN_DIR="${QYSTEMD_RUN_DIR}"
QYSTEMD_RUN_FILE="${QYSTEMD_RUN_FILE}"
QYSTEMD_PID_FILE="${QYSTEMD_PID_FILE}"
QYSTEMD_RUNLOG_FILE="${QYSTEMD_RUNLOG_FILE}"

EOF

  #PYTHEETOR="${PYTHEETOR}"
  #QYSTEMD_EXECUTOR_ORIGIN_FILE="${QYSTEMD_EXECUTOR_ORIGIN_FILE}"
  #KURT=HANS
  ## Comment

  # -------------------------
  #  erase_fs_path "$(cup_exe_file)"
  #  ln -s "${QYSTEMD_EXECUTOR_ORIGIN_FILE}" "$(cup_exe_file)"
  #  #  ln -s /opt/projects/hedeninge/qystemd/sh/stuff/cup_exe_template.sh "$(cup_exe_file)"
  #  #  cp -a /opt/projects/hedeninge/qystemd/sh/stuff/cup_exe_template.sh "$(cup_exe_file)"
  #  #  chmod +x "$(cup_exe_file)"
}

erase_config_dir() {
  debug_func
  if [[ -d "$(get_config_dir)" ]]; then
    erase_fs_path "$(get_config_dir)"
  fi
}

get_config_dir() {
  if systemd_mode_is_user; then
    echo "${HOME}/.config/${QYSTEMD_NAME}"
  else
    echo "/etc/${QYSTEMD_NAME}"
  fi
}

get_config_file() {
  local which
  which="$1"
  if [[ ${which} == 'env' ]]; then
    echo "$(get_config_dir)/qystemd.conf"
    #    echo "$(get_config_dir)/.env.qystemd"
  elif [[ ${which} == 'exe' ]]; then
    echo "$(get_config_dir)/qystemd_executor.sh"
  else
    fail "Unknown config file: ${which}"
  fi
}

# endregion develop

# region util
test() {
  debug_func
  messagize "test qystemd.lib $*"
  debug_var QYSTEMD_DIR
}

systemd_mode_is_user() {
  [[ "$QYSTEMD_SYSTEMD_MODE" == 'user' ]]
}

erase_fs_path() {
  if [[ ! -e $1 && ! -L $1 ]]; then
    echo "NOT Erasing; path does not exist: $1"
    return 1
  fi
  debug "Erasing: $1"
  #create a directory in /tmp with unique name based on time:
  destin_dir="/tmp/erased/erase_$(date +%s)"
  mkdir -p "${destin_dir}"
  #move the file to the new directory:
  mv "$1" "${destin_dir}"
}
# endregion util

# region load
init_lib() {
  #  debug_func
  qystemd_initialize "$@"
  #  if [[ $1 == '--habitize' ]]; then
  #    shift
  #    habitize "$@"
  #  fi
}

init_lib "$@"
# endregion load
