qystemd_execute() {
  debug_func
  #  local progress_file
  #  progress_file='/tmp/qystemd.progress'

  get_main_pid() {
    if [[ $1 == '--mainpid' ]]; then
      local main_pid
      shift
      main_pid=$1
      shift
      echo "${main_pid}"
      return 0
    fi
    return 1
  }

  #  set_progress() {
  #    local progress
  #    progress=$1
  #    shift
  #    echo "${progress}" >"${progress_file}"
  #  }
  #
  #  get_progress() {
  #    local progress
  #    progress=$(cat "${progress_file}")
  #    ## strip whitespace:
  #    progress=${progress//[[:blank:]]/}
  #    echo "${progress}"
  #  }
  #
  #  is_progress() {
  #    local progress
  #    progress=$(get_progress)
  #    echo "${progress}"
  #    [[ "${progress}" == "$1" ]]
  #  }

  ## OVERRIDING same function in qortrollor.lib.sh !
  start_java_args() {
    debug_func
    messagize 'start_java_args in qystemd_execute'
    messagize "${java_args[@]}"

    # shellcheck disable=SC2128
    # shellcheck disable=SC2154
    if [[ -n ${java_args} ]]; then
      debug_var run_log_filename
      debug "$(realpath "${run_log_filename}")"
      ## using bash "dynamic scope":
      nice -n 20 java "$@" 1>"${run_log_filename}" #2>&1 &
    else
      error 'java_args is empty'
    fi
  }

  execute_start() {
    debug_func
    echo 'params:' "$@"
    [[ -f "${QYSTEMD_RUNLOG_FILE}" ]] && rm "${QYSTEMD_RUNLOG_FILE}"
    #    [[ -f "${pid_file}" ]] && rm "${pid_file}"
    #    set_progress starting
    systemd-notify --ready
    prep_start "$@"
    #    set_progress started
  }

  execute_start_post() {
    debug_func
    echo 'params:' "$@"
    if MAINPID=$(get_main_pid "$@"); then
      debug "MAINPID: ${MAINPID}"
      if [[ -n ${QYSTEMD_PID_FILE} ]]; then
        indx=0
        while [[ ! -f "${QYSTEMD_RUNLOG_FILE}" ]]; do
          indx=$((indx + 1))
          if [[ $indx -gt 20 ]]; then
            debug "gave up waiting for ${QYSTEMD_RUNLOG_FILE} to be created"
            break
          else
            debug "Waiting for ${QYSTEMD_RUNLOG_FILE} to be created..."
            sleep 0.1
          fi
        done
        sleep 0.1
        echo "${MAINPID}" >"${QYSTEMD_PID_FILE}"
        debug "Wrote MAINPID ${MAINPID} to ${QYSTEMD_PID_FILE}"
      fi
    fi
    return 0
  }

  execute_stop() {
    debug_func
    echo 'params:' "$@"

    if MAINPID=$(get_main_pid "$@"); then
      debug_var MAINPID
      shift
      if [[ -n ${MAINPID} ]]; then
        ## is pid a number?:
        if [[ ${MAINPID} =~ ^[0-9]+$ ]]; then
          ## is pid running:
          if ps -p "${MAINPID}" >/dev/null; then
            #            set_progress stopping
            killorize "${MAINPID}"
            #            set_progress stopped
          else
            error "MAINPID ${MAINPID} is not running"
            return 1
          fi
        else
          error "MAINPID ${MAINPID} is not a number"
          return 1
        fi
      else
        error 'MAINPID is empty'
        return 1
      fi
    fi
    return 0
  }

  local instrux
  instrux=$1
  shift
  cd "${QYSTEMD_RUN_DIR}" || error "Unable to cd to QYSTEMD_RUN_DIR: ${QYSTEMD_RUN_DIR}"
  "execute_${instrux}" "$@"

}
