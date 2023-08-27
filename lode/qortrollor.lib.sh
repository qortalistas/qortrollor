#!/usr/bin/env bash

# region habitize
habitize() {
  debug_func
  local default_jvm_memory_args candidate_dir prev_dir default_preparor_jar_file
  #  default_jvm_memory_args="-Xss256k -Xmx256m"
  default_jvm_memory_args=''
  unset QORTROL_DIR
  export QORTROL_NOISY_DEBUG
  if [[ $1 == '--noisy' ]]; then
    shift
    #    noisy=1
    QORTROL_NOISY_DEBUG='true'
  fi
  if [[ $1 == '--showcall' ]]; then
    shift
    # set name to stem of $0:
    name="${0##*/}"
    #strip extension:
    name="${name%.*}"
    messagize "Running Script: ${name}"
  fi
  #### LOCATE QORTROL_DIR:
  env_name='.env.habitat'
  env_template_name='.env.template.habitat'
  QORTROLLOR_LIB="$(realpath "${BASH_SOURCE[0]}")"
  candidate_dir="$(dirname "${QORTROLLOR_LIB}")"
  #  candidate_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
  while [[ -z ${QORTROL_DIR} ]]; do
    #    debug "candidate_dir: ${candidate_dir}"
    canditate="${candidate_dir}/${env_name}"
    if [[ -f ${canditate} ]]; then
      QORTROL_DIR="${candidate_dir}"
      break
    fi
    canditemplate="${candidate_dir}/${env_template_name}"
    if [[ -f ${canditemplate} ]]; then
      echo '#### settings here might be overridden by settings in the QORTAL_DIR' >"${canditate}"
      cat "${canditemplate}" >>"${canditate}"
      #      cp -a "${canditemplate}" "${canditate}"
      messagize "Created ${canditate}"
      QORTROL_DIR="${candidate_dir}"
      break
    fi
    prev_dir="${candidate_dir}"
    candidate_dir="$(dirname "${candidate_dir}")"
    if [[ "${prev_dir}" == "${candidate_dir}" ]]; then
      fail "Unable to find ${env_name}"
    fi
  done
  QORTROL_ENV_TEMPLATE_FILE="${QORTROL_DIR}/${env_template_name}"
  # shellcheck disable=SC1090
  . "${QORTROL_DIR}/${env_name}"
  Q_HABITAT_DIR="$(dirname "${QORTROL_DIR}")"
  QORTROL_LODE_DIR="${QORTROL_DIR}/lode"
  QORTROL_JARS_DIR="${QORTROL_JARS_DIR:-"${QORTROL_LODE_DIR}"}"
  #  QORTROL_JARS_DIR="${QORTROL_LODE_DIR}"

  default_preparor_jar_file="${QORTROL_JARS_DIR}/preparor.jar"
  QORTROL_PREPAROR_JAR_FILE="${QORTROL_PREPAROR_JAR_FILE:-"${default_preparor_jar_file}"}"
  QORTROL_JVM_ARGS="${QORTROL_JVM_ARGS:-"${default_jvm_memory_args}"}"
  QORTROL_NOISY_DEBUG="${QORTROL_NOISY_DEBUG:-'false'}"
  QORTROL_KILL_TIMEOUTSEC="${QORTROL_KILL_TIMEOUTSEC:-20}"
  Q_HABITAT_ENV_FILE="${Q_HABITAT_DIR}/.env.qortrollor"
  Q_HABITAT_SETTINGS_DIR="${Q_HABITAT_SETTINGS_DIR:-"${Q_HABITAT_DIR}"}"
  Q_HABITAT_PID_FILENAME='run.pid'
  Q_HABITAT_RUNLOG_FILENAME='run.log'
  QORTROLLED_DIR="${Q_HABITAT_DIR}/_qortrolled"
  QORTROLLED_LOG_DIR="${QORTROLLED_DIR}/log"

  ####  check_installed_correctly
  qortal_jar_file="${Q_HABITAT_DIR}/qortal.jar"
  [[ -f ${qortal_jar_file} ]] || fail "Could not find qortal.jar at ${qortal_jar_file}"
  #### Load Q_HABITAT_ENV_FILE
  if [[ -f ${Q_HABITAT_ENV_FILE} ]]; then
    # shellcheck disable=SC1090
    . "${Q_HABITAT_ENV_FILE}"
  fi

  # if Q_HABITAT_SETTINGS_DIR is not absolute, make it absolute:
  if [[ ! ${Q_HABITAT_SETTINGS_DIR} =~ ^/ ]]; then
    Q_HABITAT_SETTINGS_DIR="${Q_HABITAT_DIR}/${Q_HABITAT_SETTINGS_DIR}"
  fi

  [[ $QORTROL_PREPAROR_JAR_FILE =~ \.jar$ ]] ||
    QORTROL_PREPAROR_JAR_FILE="${QORTROL_PREPAROR_JAR_FILE}.jar" # add .jar if not present
  #  # if QORTROL_PREPAROR_JAR_FILE is not absolute, make it absolute:
  if [[ ! ${QORTROL_PREPAROR_JAR_FILE} =~ ^/ ]]; then
    QORTROL_PREPAROR_JAR_FILE="${QORTROL_JARS_DIR}/${QORTROL_PREPAROR_JAR_FILE}"
  fi

  if [[ -z ${QORTROL_JAVA_EXE} ]]; then
    QORTROL_JAVA_EXE="$(which java)"
  fi

  #  #  if [[ -n ${noisy} ]]; then
  #  debug_vars Q_HABITAT_DIR QORTROL_DIR QORTROL_JARS_DIR \
  #    Q_HABITAT_SETTINGS_DIR QORTROL_PREPAROR_JAR_FILE Q_HABITAT_PID_FILENAME Q_HABITAT_RUNLOG_FILENAME
  #  #  fi
  Q_HABITAT_IZED='true'
  #  modifyze
}

java_run() {
  ${QORTROL_JAVA_EXE} "$@"
}

check_installed_correctly() {
  habitize_if_needed "$@"
  if [[ -f ${Q_HABITAT_DIR}/qortal.jar && -f ${Q_HABITAT_ENV_FILE} ]]; then
    return 0
  fi
  fail "Qortrollor is not installed correctly at ${Q_HABITAT_DIR}"
  echo "${env_file}"
}

is_habitized() {
  [[ ${Q_HABITAT_IZED} == 'true' ]]
}

habitize_if_needed() {
  is_habitized && return 0
  check_installed_correctly
  habitize "$@" || fail "Unable to habitize"
}

fail_if_not_habitized() {
  is_habitized || fail "Not habitized"
}
# endregion habitize

# region modify
install_modify() {
  debug_func
  habitize_if_needed
  local operation
  operation="${1:-install}"
  #  debug_var operation
  _substallize "${operation}"
}

is_qortrollor_installed() {
  [[ -f ${Q_HABITAT_ENV_FILE} ]]
}

get_uninstall_now_dir() {
  local bu_uninstalled_dir bu_now_dir
  bu_uninstalled_dir="${QORTROLLED_DIR}/backup_when_uninstalled"
  bu_now_dir="${bu_uninstalled_dir}/$(date +%Y%m%d_%H%M%S)"
  echo "${bu_now_dir}"
}

_substallize() {
  debug_func
  local env_file bu_now_dir script_source_postfix script_installed_postfix \
    json_settings_file_name
  #  env_file="${Q_HABITAT_DIR}/.env.qortrollor"
  env_file="${Q_HABITAT_ENV_FILE}"
  #    bu_main_dir="${QORTROL_DIR}/bu_main"
  #    bu_now_dir="${bu_main_dir}/$(date +%Y%m%d_%H%M%S)"

  bu_installed_dir="${QORTROLLED_DIR}/backup_when_installed"
  #  bu_uninstalled_dir="${QORTROLLED_DIR}/backup_when_uninstalled"
  #  bu_now_dir="${bu_uninstalled_dir}/$(date +%Y%m%d_%H%M%S)"
  bu_now_dir="$(get_uninstall_now_dir)"

  script_source_postfix='_manually.sh'
  script_installed_postfix='_qortrollor_manually.sh'
  json_settings_file_name='settings.json'
  yaml_settings_file_name='settings.yaml'
  log4j2_file_name='log4j2.properties'
  #  json_bu_settings_file_name="_bu.ori.${json_settings_file_name}"

  is_installing() {
    [[ "${operation}" == 'install' ]]
  }

  subsub_installize() {
    debug_func
    if is_qortrollor_installed; then
      messagize "Already installed"
      return 0
    fi
    messagize "Installing..."
    local origin_file destin_file name
    #### BACKUP DIR:
    mkdir -p "${bu_installed_dir}" || fail "Unable to create ${bu_installed_dir}"
    #### ENV FILE:
    echo 'MODIFIED=true' >"${env_file}" || fail "Unable to create ${env_file}"
    echo '# Settings here override settings in ./qortrollor/.env.habitat' >>"${env_file}"
    cat "${QORTROL_ENV_TEMPLATE_FILE}" >>"${env_file}"
    messagize "Created ${env_file}"

    #### SETTINGS FILE:
    origin_file="${Q_HABITAT_DIR}/${json_settings_file_name}"
    #    destin_file="${Q_HABITAT_DIR}/${json_bu_settings_file_name}"
    destin_file="${bu_installed_dir}/${json_settings_file_name}"
    if mv "${origin_file}" "${destin_file}"; then
      messagize "Moved ${origin_file} to ${destin_file}"
    else
      error "Unable to mv ${origin_file} to ${destin_file}"
    fi
    #    mv "${origin_file}" "${destin_file}" ||
    #      fail "Unable to mv ${origin_file} to ${destin_file}"

    #### log4j2 FILE:
    origin_file="${Q_HABITAT_DIR}/${log4j2_file_name}"
    destin_file="${bu_installed_dir}/${log4j2_file_name}"
    if cp -a "${origin_file}" "${destin_file}"; then
      messagize "Created ${destin_file}"
      get_log4j2_custom_properties >>"${origin_file}" || error "Unable to modify ${origin_file}"
    else
      error "Unable to create ${destin_file}"
    fi

    #### SCRIPT FILES:
    for name in "start" "stop"; do
      ## backup original scripts:
      origin_file="${Q_HABITAT_DIR}/${name}.sh"
      destin_file="${bu_installed_dir}/${name}.sh"
      if [[ -f ${origin_file} ]]; then
        mv "${origin_file}" "${destin_file}"
        messagize "Moved ${origin_file} to ${destin_file}"
      else
        error "Unable to mv ${origin_file} to ${destin_file}"
      fi
      ## install new scripts:
      origin_file="${QORTROL_LODE_DIR}/${name}${script_source_postfix}"
      destin_file="${Q_HABITAT_DIR}/${name}${script_installed_postfix}"
      if cp -a "${origin_file}" "${destin_file}"; then
        messagize "Created ${destin_file}"
      else
        error "Unable to create ${destin_file}"
      fi
    done

    #### YAML SETTINGS FILE:
    instate_yaml_template
    #### reverse
    cd "${bu_installed_dir}" || fail "Unable to cd ${bu_installed_dir}"
    java_run -jar "${QORTROL_PREPAROR_JAR_FILE}" reverse
    origin_file="${bu_installed_dir}/${yaml_settings_file_name}"
    destin_file="${Q_HABITAT_SETTINGS_DIR}/${yaml_settings_file_name}"
    # replace "#placeholder" in ${destin_file} with content of ${origin_file}:
    sed -i -e '/#placeholder/ {' -e 'r '"${origin_file}" -e 'd' -e '}' "${destin_file}" ||
      fail "Unable to replace #placeholder in ${destin_file} with content of ${origin_file}"

    messagize "Install Done"
  }

  subsub_uninstallize() {
    debug_func
    if ! is_qortrollor_installed; then
      messagize "Already uninstalled"
      return 0
    fi
    messagize "Uninstalling..."
    local file_name origin_file destin_file name
    [[ -d ${bu_now_dir} ]] || mkdir -p "${bu_now_dir}" || fail "Unable to create ${bu_now_dir}"
    #### ENV FILE:
    #    messagize "Moving ${env_file} to ${bu_now_dir}"
    #    mv "${env_file}" "${bu_now_dir}/" || fail "Unable to move ${env_file} to ${bu_now_dir}/"
    if mv "${env_file}" "${bu_now_dir}/"; then
      messagize "Moved ${env_file} to ${bu_now_dir}"
    else
      error "Unable to move ${env_file} to ${bu_now_dir}"
    fi

    #### SCRIPT FILES:
    for name in "start" "stop"; do
      ## backup new scripts:
      file_name="${name}${script_installed_postfix}"
      origin_file="${Q_HABITAT_DIR}/${file_name}"
      destin_file="${bu_now_dir}/${file_name}"
      if [[ -f ${origin_file} ]]; then
        #        messagize "Moving ${origin_file} to ${destin_file}"
        if mv "${origin_file}" "${destin_file}"; then
          messagize "Moved ${origin_file} to ${destin_file}"
        else
          error "Unable to move ${origin_file} to ${destin_file}"
        fi
      else
        error "Unable to locate ${origin_file}"
      fi
      ## reinstate original scripts:
      origin_file="${bu_installed_dir}/${name}.sh"
      destin_file="${Q_HABITAT_DIR}/${name}.sh"
      if [[ -f ${origin_file} ]]; then
        #        messagize "Moving ${origin_file} to ${destin_file}"
        #        mv "${origin_file}" "${destin_file}"
        if mv "${origin_file}" "${destin_file}"; then
          messagize "Moved ${origin_file} to ${destin_file}"
        else
          error "Unable to move ${origin_file} to ${destin_file}"
        fi
      else
        error "Unable to locate ${origin_file}"
      fi
    done

    #### SETTINGS FILES:
    ## backup new settings:
    for ext in "yaml" "json"; do
      local file_name origin_file destin_file
      file_name="settings.${ext}"
      origin_file="${Q_HABITAT_DIR}/${file_name}"
      destin_file="${bu_now_dir}/${file_name}"
      if [[ -f ${origin_file} ]]; then
        messagize "Moving ${origin_file} to ${destin_file}"
        mv "${origin_file}" "${destin_file}"
      fi
    done
    ## reinstate original settings:
    origin_file="${bu_installed_dir}/${file_name}"
    destin_file="${Q_HABITAT_DIR}/${file_name}"
    if [[ -f ${origin_file} ]]; then
      messagize "Moving ${origin_file} to ${destin_file}"
      mv "${origin_file}" "${destin_file}"
    fi

    #### log4j2 FILE:
    local bu_ori_file seminal_file
    bu_ori_file="${bu_installed_dir}/${log4j2_file_name}"
    #    bu_ori_file="${Q_HABITAT_DIR}/_bu.ori.log4j2.properties"
    if [[ -f ${bu_ori_file} ]]; then
      seminal_file="${Q_HABITAT_DIR}/${log4j2_file_name}"
      #      seminal_file="${Q_HABITAT_DIR}/log4j2.properties"
      if [[ -f ${seminal_file} ]]; then
        messagize "Moving ${seminal_file} to ${bu_now_dir}"
        mv "${seminal_file}" "${bu_now_dir}/" || error "Unable to move ${seminal_file} to ${bu_now_dir}/"
      fi
      messagize "Moving ${bu_ori_file} to ${seminal_file}"
      mv "${bu_ori_file}" "${seminal_file}" || error "Unable to move ${bu_ori_file} to ${seminal_file}"
    fi

    #### SHOULD BE LAST:
    origin_file="${bu_installed_dir}/${json_settings_file_name}"
    destin_file="${Q_HABITAT_DIR}/${json_settings_file_name}"
    #    debug_vars origin_file destin_file
    if [[ -f ${origin_file} ]]; then
      messagize "Moving ${origin_file} to ${destin_file}"
      mv "${origin_file}" "${destin_file}"
    fi
    # if bu_installed_dir is empty move it to bu_now_dir:
    #    if [[ -z $(ls -A "${bu_installed_dir}") ]]; then
    messagize "Moving ${bu_installed_dir} to ${bu_now_dir}"
    mv "${bu_installed_dir}" "${bu_now_dir}"
    #    fi

    messagize "Uninstall Done"
  }

  if is_installing; then
    subsub_installize
  else
    subsub_uninstallize
  fi
}

get_log4j2_custom_properties() {
  echo
  echo '# QORTROLLOR:'
  echo 'appender.rolling.strategy.type=DefaultRolloverStrategy'
  echo 'appender.rolling.fileName=log/qortal.log'
  echo 'appender.rolling.filePattern = log/qortal.%i.log.gz'
}
# endregion modify

# region super_modify
super_modifyze() {
  debug_func
  declare -i indx
  indx=-1
  declare -a choices

  append_choice() {
    local choice
    ((indx++))
    texting append "${indx}) $1"
    choices+=("$2")
  }

  texting begin 'Qortrollor and Qystemd installor ...'
  if is_qortrollor_installed; then
    texting append ' - Qortrollor is installed.'
  else
    texting append ' - Qortrollor is not installed.'
  fi
  #  qortrollor_load_manipulate_qystemd
  if is_qystemd_installed; then
    texting append ' - Qystemd is installed.'
  else
    texting append ' - Qystemd is not installed.'
  fi
  texting print
  #  messagize 'Wot do you want to do?' '1) Install Qortrollor' '2) Uninstall Qortrollor' '3) Install Qystemd' '4) Uninstall Qystemd' '5) Install Qortrollor and Qystemd' '6) Uninstall Qortrollor and Qystemd' '7) Exit'
  texting begin 'Wot do you want to do?'
  append_choice 'Exit' exit
  if is_qortrollor_installed && is_qystemd_installed; then
    append_choice 'Uninstall Qortrollor and Qystemd' uninstall_both
    append_choice 'Uninstall only Qystemd' uninstall_only_qystemd
  elif ! is_qortrollor_installed && ! is_qystemd_installed; then
    append_choice 'Install Qortrollor and Qystemd' install_both
    append_choice 'Install only Qortrollor' install_only_qortrollor
  elif is_qortrollor_installed; then
    append_choice 'Install Qystemd' install_only_qystemd
    append_choice 'Uninstall Qortrollor' uninstall_only_qortrollor
  fi
  texting print
  #  debug "choices: ${choices[*]}"
  # ask for choice:
  local choice is_choice_valid choise_func
  is_choice_valid=false
  while ! ${is_choice_valid}; do
    is_choice_valid=true
    read -r -p 'Enter choice: ' choice
    if [[ -z ${choice} ]]; then
      is_choice_valid=false
      error 'No choice entered.'
    elif ! is_number "${choice}"; then
      is_choice_valid=false
      error "Choice '${choice}' is not a number."
    elif ((choice < 0 || choice > indx)); then
      is_choice_valid=false
      error "Choice '${choice}' is not a valid choice; must be between 0 and ${indx}."
    fi
    [[ ${is_choice_valid} == true ]] && break
    messagize 'Invalid choice. Try again.'
  done
  #  debug_var choice
  choise_func="${choices[choice]}"
  #  debug_var choise_func

  if [[ ${choise_func} == 'exit' ]]; then
    messagize 'Exiting.'
    exit 0
  elif [[ ${choise_func} == 'install_both' ]]; then
    messagize 'Installing Qortrollor and Qystemd.'
    install_modify install
    qystemd_install
  elif [[ ${choise_func} == 'uninstall_both' ]]; then
    messagize 'Uninstalling Qortrollor and Qystemd.'
    qystemd_uninstall
    install_modify uninstall
  elif [[ ${choise_func} == 'uninstall_only_qystemd' ]]; then
    messagize 'Uninstalling Qystemd.'
    qystemd_uninstall
  elif [[ ${choise_func} == 'install_only_qystemd' ]]; then
    messagize 'Installing Qystemd.'
    qystemd_install
  elif [[ ${choise_func} == 'install_only_qortrollor' ]]; then
    messagize 'Installing Qortrollor.'
    install_modify install
  elif [[ ${choise_func} == 'uninstall_only_qortrollor' ]]; then
    messagize 'Uninstalling Qortrollor.'
    install_modify uninstall
  else
    fail "Unknown choice function '${choise_func}'"
  fi
}
# endregion super_modify

# region startstop
prep_start() {
  debug_func
  check_installed_correctly "$@"
  #  habitize_if_needed "$@"
  #  messagize "Starting habitat..."
  #  fail "testning"
  preparorize
  startorize "$@"
}

preparorize() {
  debug_func
  fail_if_not_habitized
  yaml_file="${Q_HABITAT_SETTINGS_DIR}/settings.yaml"
  instate_yaml_template
  #  if ! [[ -f ${yaml_file} ]]; then
  #    if cp -a "${QORTROL_LODE_DIR}/settings.template.yaml" "${yaml_file}"; then
  #      messagize "Created ${yaml_file}"
  #    else
  #      fail "Unable to create ${yaml_file}"
  #    fi
  #  fi
  debug_vars Q_HABITAT_SETTINGS_DIR QORTROL_PREPAROR_JAR_FILE
  cd "${Q_HABITAT_SETTINGS_DIR}" || fail "Unable to cd to Q_HABITAT_SETTINGS_DIR: ${Q_HABITAT_SETTINGS_DIR}"
  [[ -f ${QORTROL_PREPAROR_JAR_FILE} ]] || fail "QORTROL_PREPAROR_JAR_FILE not found: ${QORTROL_PREPAROR_JAR_FILE}"
  java_run -jar "${QORTROL_PREPAROR_JAR_FILE}"
}

instate_yaml_template() {
  debug_func
  fail_if_not_habitized
  yaml_file="${Q_HABITAT_SETTINGS_DIR}/settings.yaml"
  if ! [[ -f ${yaml_file} ]]; then
    if cp -a "${QORTROL_LODE_DIR}/settings.template.yaml" "${yaml_file}"; then
      messagize "Created ${yaml_file}"
    else
      fail "Unable to create ${yaml_file}"
    fi
  fi
}

startorize() {
  debug_func
  fail_if_not_habitized
  cd "${Q_HABITAT_DIR}" || fail "Unable to cd to Q_HABITAT_DIR: ${Q_HABITAT_DIR}"
  local jar_file run_log_filename settings_file pid
  declare -a java_args
  jar_file='qortal.jar'
  pid_file="${Q_HABITAT_PID_FILENAME}"
  run_log_filename="${Q_HABITAT_RUNLOG_FILENAME}"
  settings_file='settings.json'
  if [[ ${Q_HABITAT_SETTINGS_DIR} != "${Q_HABITAT_DIR}" ]]; then
    settings_file="${Q_HABITAT_SETTINGS_DIR}/${settings_file}"
  fi
  if pid=$(is_pid_file_running); then
    fail "Already running: ${pid}"
  fi
  #  debug_vars jar_file pid_file run_log_filename settings_file
  touch "${run_log_filename}"
  touch "${pid_file}"
  [[ -f ${run_log_filename} ]] || fail "run_log_filename not found: ${run_log_filename}"
  [[ -f ${pid_file} ]] || fail "pid_file not found: ${pid_file}"
  [[ -f ${jar_file} ]] || fail "jar_file not found: ${jar_file}"
  [[ -f ${settings_file} ]] || fail "settings_file not found: ${settings_file}"
  java_args=(
    -Djava.net.preferIPv4Stack=false
  )
  # if QORTROL_JVM_ARGS contains numbers, then it is probably valid QORTROL_JVM_ARGS, so we will use it:
  if [[ "${QORTROL_JVM_ARGS}" =~ [0-9] ]]; then
    # shellcheck disable=SC2206
    java_args+=(${QORTROL_JVM_ARGS})
  fi

  java_args+=(-jar "${jar_file}")
  echo 'java_args: ' "${java_args[@]}"
  if [[ $1 == '--dry-run' ]]; then
    debug '--dry-run'
  else
    echo "jar_file and settings_file exist, so we will run now! ..."
    start_java_args "${java_args[@]}"
  fi
}

start_java_args() {
  debug_func
  nohup nice -n 19 "${QORTROL_JAVA_EXE}" "$@" 1>"${run_log_filename}" 2>&1 &
  pid=$!
  echo ${pid} >"${pid_file}"
  echo qortrollor running qortal.jar as pid ${pid}
}

stoporize() {
  debug_func
  fail_if_not_habitized
  cd "${Q_HABITAT_DIR}" || fail "Unable to cd to Q_HABITAT_DIR: ${Q_HABITAT_DIR}"
  local pid
  if pid=$(is_pid_file_running); then
    debug "running pid: ${pid}"
    killorize "${pid}"
  else
    debug "no running pid found"
  fi
}

killorize() {
  debug_func
  local pid
  pid="$1"

  endgame() {
    rm -f "${Q_HABITAT_PID_FILENAME}"
    return 0
  }

  if kill -15 "${pid}" 2>/dev/null; then
    debug "killed pid ${pid}"
    debug "Qortal node should be shutting down"
    if is_pid_file_valid; then
      echo -n "Monitoring for Qortal node to end"
      indx=0
      while s=$(ps -p "$pid" -o stat=) && [[ "$s" && "$s" != 'Z' ]]; do
        indx=$((indx + 1))
        if [[ $indx -gt ${QORTROL_KILL_TIMEOUTSEC} ]]; then
          echo
          echo "Qortal node did not end gracefully after ${QORTROL_KILL_TIMEOUTSEC} seconds"
          echo "Killing pid ${pid}"
          kill -9 "${pid}"
          error "Qortal node was HARD KILLED!"
          endgame
          return 0
        fi
        echo -n .
        sleep 1
      done
      echo
      echo "Qortal ended gracefully$"
      endgame
    fi
  else
    error "Unable to kill pid ${pid}"
    return 1
  fi
}
# endregion startstop

# region pid
is_pid_file_existing() {
  [[ -f ${Q_HABITAT_PID_FILENAME} ]]
}

is_pid_file_valid() {
  local pid
  #  [[ -f ${Q_HABITAT_PID_FILENAME} ]] || return 1
  is_pid_file_existing || return 1
  pid="$(cat "${Q_HABITAT_PID_FILENAME}")" >/dev/null 2>&1 || return 1
  # is pid a number?:
  if [[ ${pid} =~ ^[0-9]+$ ]]; then
    echo "${pid}"
    return 0
  fi
  return 1
}

is_pid_file_running() {
  local pid
  if pid=$(is_pid_file_valid); then
    if ps -p "${pid}" >/dev/null; then
      echo "${pid}"
      return 0
    fi
  fi
  return 1
}
# endregion pid

# region util
fail() {
  #  echo "FAIL: $1" 1>&2
  print_color '31' "FAIL: $*" #red
  exit 1
}

error() {
  print_color '31' "ERROR: $*" #red
}

messagize() {
  print_color '38;5;94' "MESSAGE: $*" #dscreet yellowish:
  #  print_color '1;33' "MESSAGE: $*" #bright yellow:
}

messagize_noisy() {
  #  print_color '38;5;94' "MESSAGE: $*" #dscreet yellowish:
  print_color '1;33' "MESSAGE: $*" #bright yellow:
}

debug() {
  _debug "DEBUG: $*"
}

debug_var() {
  local var_name
  var_name=$1
  _debug " - VAR: ${var_name} = '${!var_name}'"
}

debug_vars() {
  _debug '---- debug_vars ----'
  local var_name
  for var_name in "$@"; do
    _debug " - VAR: ${var_name} = '${!var_name}'"
  done
}

debug_func() {
  is_noisy &&
    print_color '34' "FUNC ${FUNCNAME[1]}" "$@" #blue
}

_debug() {
  is_noisy && print_color '38;5;240' "$*" #dark greyish
  #    print_color '1;37' "$*" #greyish
}

print_color() {
  local color_code
  color_code=$1
  shift
  echo -e "\e[${color_code}m$*\e[0m"
}

is_noisy() {
  [[ ${QORTROL_NOISY_DEBUG} == 'true' ]]
}

is_number() {
  [[ $1 =~ ^[0-9]+$ ]]
}

is_user_root() {
  [[ ${EUID} == 0 ]]
}

texting() {
  local instrux nl
  nl=$'\n'
  texting_append() {
    QTXT+="$*$nl"
  }
  texting_begin() {
    QTXT=''
    texting_append "$@"
  }
  texting_debug() {
    _debug "$QTXT"
  }
  texting_messagize() {
    messagize "$QTXT"
  }
  texting_print() {
    print_color '1;35' "$QTXT"
    #    print_color '1;35' "TEXTING: $QTXT"
  }
  instrux=$1
  shift
  "texting_${instrux}" "$@"
}

test() {
  debug "test qortrollor.lib $*"
}
# endregion util

# region qystemd
qortrollor_load_manipulate_qystemd() {
  #  debug_func
  #  local qystemd_file
  QYSTEMD_DIR="${QORTROL_LODE_DIR}/qystemd"
  lib="${QYSTEMD_DIR}/qystemd.manipulate.lib.sh"
  if [[ -f ${lib} ]]; then
    # shellcheck disable=SC1090
    source "${lib}"
  else
    fail "Unable to find qystemd lib: ${lib}"
  fi
}

qortrollor_load_execute_qystemd_lib() {
  debug_func
  QYSTEMD_DIR="${QORTROL_LODE_DIR}/qystemd"
  lib="${QYSTEMD_DIR}/qystemd.execute.lib.sh"
  if [[ -f ${lib} ]]; then
    # shellcheck disable=SC1090
    source "${lib}"
  else
    fail "Unable to find qystemd execute lib: ${lib}"
  fi
}

is_qystemd_installed() {
  #  debug_func
  qortrollor_load_manipulate_qystemd
  [[ -d "$(get_config_dir)" ]]
}
# endregion qystemd

# region develop
develop() {
  debug_func
  toggle_install
}

toggle_install() {
  debug_func
  if is_qortrollor_installed; then
    messagize "DESTROY"
    install_modify uninstall
  else
    messagize "CREATE"
    install_modify install
  fi
}

status() {
  debug_func

  if ! is_qortrollor_installed; then
    messagize "Qortrollor is NOT INSTALLED"
    exit 1
  fi
  messagize "Qortrollor is  INSTALLED"

  if is_qystemd_installed; then
    messagize "Qystemd is INSTALLED"
    qystemd_status
  else
    messagize "Qystemd is NOT INSTALLED"
  fi

  #  local txt
  #  txt="NOT INSTALLED"
  #  if is_qortrollor_installed; then
  #    txt="INSTALLED"
  #  fi
  #  messagize "Qotrollor is ${txt}"
  #  txt="NOT INSTALLED"
  #  if is_qystemd_installed; then
  #    messagize "Qystemd is INSTALLED"
  #    qystemd_status
  #  else
  #    messagize "Qystemd is NOT INSTALLED"
  #  fi
}
# endregion develop

# region command
do_command() {
  debug_func
  local command
  command=$1
  shift
  case ${command} in
  'test_command')
    test_command "$@"
    ;;
  'monitor')
    monitor "$@"
    ;;
  'start')
    prep_start "$@"
    ;;
  'stop')
    stoporize "$@"
    ;;
  'status')
    status "$@"
    ;;
  #else respond unknown command:
  *)
    fail "Unknown command: ${command}"
    ;;
  esac

  #  'install')
  #    install_modify install "$@"
  #    ;;
  #  'uninstall')
  #    install_modify uninstall "$@"
  #    ;;
  #  'develop')
  #    develop "$@"
  #    ;;
  #  'super_modify')
  #    super_modifyze "$@"
  #    ;;
  #  'preparorize')
  #    preparorize "$@"
  #    ;;
  #  'qystemd')
  #    qystemd "$@"
  #    ;;
  #  'qystemd_status')
  #    qystemd_status "$@"
  #    ;;
  #  'qystemd_install')
  #    qystemd_install "$@"
  #    ;;
  #  'qystemd_uninstall')
  #    qystemd_uninstall "$@"
  #    ;;
  #  'qystemd_start')
  #    qystemd_start "$@"
  #    ;;
  #  'qystemd_stop')
  #    qystemd_stop "$@"
  #    ;;
  #  'qystemd_restart')
  #    qystemd_restart "$@"
  #    ;;
  #  'qystemd_reload')
  #    qystemd_reload "$@"
  #    ;;
  #  'qystemd_status')
  #    qystemd_status "$@"
  #    ;;
  #  'qystemd_enable')
  #    qystemd_enable "$@"
  #    ;;
  #  'qystemd_disable')
  #    qystemd_disable "$@"
  #    ;;
  #  'qystemd_is_enabled')
  #    qystemd_is_enabled "$@"
  #    ;;
  #  'qystemd_is_active')
  #    qystemd_is_active "$@"
  #    ;;
  #  'qystemd_is_failed')
  #    qystemd_is_failed "$@"
  #    ;;
  #  'qystemd_is_running')
  #    qystemd_is_running "$@"
  #    ;;
  #  'qystemd_is_dead')
  #    qystemd_is_dead "$@"
  #    ;;
}

test_command() {
  debug_func
  debug "test_command: $*"
}

monitor() {
  debug_func "$@"
}

# endregion command

# region init_lib
init_lib() {
  if [[ $1 == '--habitize' ]]; then
    shift
    habitize "$@"
  elif [[ $1 == '--nohabitize' ]]; then
    shift
  else
    habitize "$@"
  fi
}

init_lib "$@"
# endregion init_lib

# region fluff
#texting() {
#  local instrux x
#  export QTXT
#
#  subtexting() {
#    local instrux_ nl
#    echo "subtexting: $*"
#    export QTXT
#    nl=$'\n'
#    append() {
#      QTXT+="$*$nl"
#    }
#    begin() {
#      QTXT=''
#      append "$@"
#    }
#    debug() {
#      echo "$QTXT"
#    }
#    instrux_=$1
#    shift
#    "${instrux_}" "$@"
#  }
#  #  instrux=$1
#  #  shift
#  echo "texting: $*"
#  x=$(subtexting "$@")
#}

#startorize() {
#  debug_func
#  fail_if_not_habitized
#  cd "${Q_HABITAT_DIR}" || fail "Unable to cd to Q_HABITAT_DIR: ${Q_HABITAT_DIR}"
#  local jar_file run_log_filename settings_file pid
#  declare -a java_args
#  jar_file='qortal.jar'
#  pid_file="${Q_HABITAT_PID_FILENAME}"
#  run_log_filename="${Q_HABITAT_RUNLOG_FILENAME}"
#  settings_file='settings.json'
#  if [[ ${Q_HABITAT_SETTINGS_DIR} != "${Q_HABITAT_DIR}" ]]; then
#    settings_file="${Q_HABITAT_SETTINGS_DIR}/${settings_file}"
#  fi
#  if pid=$(is_pid_file_running); then
#    fail "Already running: ${pid}"
#  fi
#  #  debug_vars jar_file pid_file run_log_filename settings_file
#  touch "${run_log_filename}"
#  touch "${pid_file}"
#  [[ -f ${run_log_filename} ]] || fail "run_log_filename not found: ${run_log_filename}"
#  [[ -f ${pid_file} ]] || fail "pid_file not found: ${pid_file}"
#  [[ -f ${jar_file} ]] || fail "jar_file not found: ${jar_file}"
#  [[ -f ${settings_file} ]] || fail "settings_file not found: ${settings_file}"
#  java_args=(
#    nice -n 20
#    java
#    -Djava.net.preferIPv4Stack=false
#  )
#  # shellcheck disable=SC2206
#  java_args+=(${QORTROL_JVM_ARGS})
#  java_args+=(-jar "${jar_file}")
#  echo 'java_args: ' "${java_args[@]}"
#  if [[ $1 == '--dry-run' ]]; then
#    debug '--dry-run'
#  else
#    echo "jar_file and settings_file exist, so we will run now! ..."
#    nohup \
#      "${java_args[@]}" \
#      1>"${run_log_filename}" 2>&1 &
#    pid=$!
#    echo ${pid} >"${pid_file}"
#    echo qortrollor running qortal.jar as pid ${pid}
#  fi
#}

# endregion fluff
