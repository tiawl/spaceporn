#!/usr/bin/env bash

[[ ${#} -ne 3 ]] && exit 1
OBJ="${1}"
BIN="${2}"
LOG="${3}"

[[ -d "${OBJ}" ]] && rm -r ${OBJ}
[[ -d "${BIN}" ]] && rm -r ${BIN}
[[ -f "${LOG}" ]] && rm -r ${LOG}

exit 0
