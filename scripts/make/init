#!/usr/bin/env bash

[[ ${#} -ne 6 ]] && exit 1
[[ ! -d ${1} ]] && echo "${1} is not a directory" && exit 1
[[ ! -d ${2} ]] && echo "${2} is not a directory" && exit 1
[[ ! -d ${3} ]] && echo "${3} is not a directory" && exit 1
[[ ! -d ${4} ]] && echo "${4} is not a directory" && exit 1
PREFIX=$(cd ${1} && echo ${PWD})
LPREFIX=$(cd ${2} && echo ${PWD})
SPREFIX=$(cd ${3} && echo ${PWD})
TPREFIX=$(cd ${4} && echo ${PWD})
BIN="${5}"
OBJ="${6}"

# need execute access to run binary
[[ ! -d ${PREFIX} ]] && echo "${PREFIX} is not a directory" >&2 && exit 1
[[ ! -O ${PREFIX} ]] && echo "You do not own ${PREFIX}" >&2 && exit 1
[[ ! -x ${PREFIX} ]] && echo "You are not allow to execute in ${PREFIX}" >&2 \
  && exit 1

# need write access to create and append to log file
[[ ! -d ${LPREFIX} ]] && echo "${LPREFIX} is not a directory" >&2 && exit 1
[[ ! -O ${LPREFIX} ]] && echo "You do not own ${LPREFIX}" >&2 && exit 1
[[ ! -w ${LPREFIX} ]] && echo "You are not allow to write in ${LPREFIX}" >&2 \
  && exit 1

# need read access to load shaders
# need write access to create fragment and vertex folders
[[ ! -d ${SPREFIX} ]] && echo "${SPREFIX} is not a directory" >&2 && exit 1
[[ ! -O ${SPREFIX} ]] && echo "You do not own ${SPREFIX}" >&2 && exit 1
[[ ! -r ${SPREFIX} ]] && echo "You are not allow to read in ${SPREFIX}" >&2 \
  && exit 1
[[ ! -w ${SPREFIX} ]] && echo "You are not allow to write in ${SPREFIX}" >&2 \
  && exit 1

# need read access to load textures
# need write access to generate textures atlas
[[ ! -d ${TPREFIX} ]] && echo "${TPREFIX} is not a directory" >&2 && exit 1
[[ ! -O ${TPREFIX} ]] && echo "You do not own ${TPREFIX}" >&2 && exit 1
[[ ! -r ${TPREFIX} ]] && echo "You are not allow to read in ${TPREFIX}" >&2 \
  && exit 1
[[ ! -w ${TPREFIX} ]] && echo "You are not allow to write in ${TPREFIX}" >&2 \
  && exit 1

mkdir -p ${BIN} ${OBJ} && echo "${PREFIX}" > ${BIN}/prefix \
  && echo "${LPREFIX}" > ${BIN}/lprefix \
  && echo "${SPREFIX}" > ${BIN}/sprefix \
  && echo "${TPREFIX}" > ${BIN}/tprefix && exit 0
