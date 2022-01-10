#!/usr/bin/env bash

[[ ${#} -ne 3 ]] && exit 1
[[ ! -d ${1} ]] && echo "${1} is not a directory" && exit 1
PREFIX=$(cd ${1} && echo ${PWD})
BIN="${2}"
OBJ="${3}"

[[ ! -d ${PREFIX} ]] && echo "${PREFIX} is not a directory" >&2 && exit 1
[[ ! -O ${PREFIX} ]] && echo "You do not own ${PREFIX}" >&2 && exit 1
[[ ! -r ${PREFIX} ]] && echo "You are not allow to read in ${PREFIX}" >&2 \
  && exit 1
[[ ! -w ${PREFIX} ]] && echo "You are not allow to write in ${PREFIX}" >&2 \
  && exit 1

mkdir -p ${BIN} ${OBJ} && echo "${PREFIX}" > ${BIN}/prefix && exit 0
