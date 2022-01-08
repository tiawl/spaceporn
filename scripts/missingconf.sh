#!/usr/bin/env bash

# WARNING: in C files, can not detect:
# 1) multilines comments
# 2) oneline comments after C code. ex:
#        char c = 'c' // my comment after C code

remove_array_dups() {
  declare -A tmp_array

  for i in "$@"; do
    [[ $i ]] && IFS=" " tmp_array["${i:- }"]=1
  done

  printf '%s\n' "${!tmp_array[@]}"
}

echo "--- include/*.h parsed ------------------------------"
declare -a INCL=()
for I in include/*; do
  INCL+=($(grep -h -E '#include <' ${I} | sed 's/^#include <\(.*\)>/\1/g'))
done
INCL=( $(remove_array_dups "${INCL[@]}") )
for I in ${INCL[@]}; do echo ${I}; done

echo "--- GCC library paths parsed ------------------------"
declare -a GCCPATH=()
for P in $(echo | gcc -E -Wp,-v - 2>&1); do
  [[ -d "${P}" ]] && GCCPATH+=(${P})
done
for P in ${GCCPATH[@]}; do echo ${P}; done

echo "--- absolute path for included lib built ------------"
declare -a LIB=()
for I in ${INCL[@]}; do
  for P in ${GCCPATH[@]}; do
    [[ -f "${P}/${I}" ]] && LIB+=( "${P}/${I}" )
  done
done
for L in ${LIB[@]}; do echo ${L}; done

echo "--- visited libs & found definitions ----------------"
declare -a LIBDEF=()
declare -a VISITED=()
while [[ ${#LIB[@]} -gt 0 ]]; do
  INCL=()
  for L in ${LIB[@]}; do
    LIBDEF+=($(ctags -x --kinds-c=+p-mfh ${L} | grep -E -o '^[^[:space:]]+'))
    INCL+=($(echo "$(grep -E -h '#include <' ${L} \
      | sed 's/^#include <\(.*\)>/\1/g')"))
  done
  INCL=( $(remove_array_dups "${INCL[@]}") )
  VISITED+=("${LIB[@]}")
  LIB=()
  for I in ${INCL[@]}; do
    for P in ${GCCPATH[@]}; do
      [[ -f "${P}/${I}" ]] && LIB+=( "${P}/${I}" )
    done
  done
  LIB=($(echo "${LIB[@]} ${VISITED[@]} ${VISITED[@]}" | tr ' ' '\n' | sort \
    | uniq -u))
done
LIBDEF=($(echo "${LIBDEF[@]}" | tr ' ' '\n' | sort | uniq))
echo "${#VISITED[@]} ${#LIBDEF[@]}"

echo "--- user definitions found --------------------------"
declare -a USRDEF=($(find . -type f -name '*.[ch]' -exec \
  ctags -x --kinds-c=+lpzD {} ';' | grep -E -o '^[^[:space:]]+'))
echo "${#USRDEF[@]}"

echo "--- words founds in src directory -------------------"
declare -a WORDS=($(cat src/*.c | grep -E -v '^[[:space:]]*//' \
  | grep -E -o '\b[a-zA-Z]\w*\b' | sort | uniq))
echo "${#WORDS[@]}"

echo "--- words in string ---------------------------------"
declare -a STRWORDS=($(grep -h -z -P -o '""|"(\n|.)*?[^\\]"' src/*.c \
  | tr '\0' '\n' | grep -E -o '\b[a-zA-Z]\w*\b' | sort | uniq))
echo "${#STRWORDS[@]}"

declare -a KEYWORDS=("auto break case char const continue default do double")
KEYWORDS+=("else enum extern float for goto if int long register return")
KEYWORDS+=("short signed sizeof static struct switch typedef union unsigned")
KEYWORDS+=("void volatile while true false ifdef ifndef endif define include")
KEYWORDS+=("undef bool")

echo "--- lib definitions founds in src -------------------"
echo "${WORDS[@]} ${KEYWORDS[@]} ${KEYWORDS[@]} ${USRDEF[@]} ${USRDEF[@]} ${STRWORDS[@]} ${STRWORDS[@]}" \
  | tr ' ' '\n' | sort | uniq -u
