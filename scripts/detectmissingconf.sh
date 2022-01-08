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

echo "--- include/*.h parsed ----------------------------------------"
declare -a INCL=()
for I in include/*; do
  INCL+=($(grep -h -E '#[[:space:]]*include <' ${I} \
    | sed 's/^#[[:space:]]*include <\(.*\)>/\1/g'))
done
INCL=( $(remove_array_dups "${INCL[@]}") )
for I in ${INCL[@]}; do echo ${I}; done

echo "--- GCC library paths parsed ----------------------------------"
declare -a GCCPATH=()
for P in $(echo | gcc -E -Wp,-v - 2>&1); do
  [[ -d "${P}" ]] && GCCPATH+=(${P})
done
for P in ${GCCPATH[@]}; do echo ${P}; done

echo "--- absolute path for included lib built ----------------------"
declare -a LIB=()
for I in ${INCL[@]}; do
  for P in ${GCCPATH[@]}; do
    [[ -f "${P}/${I}" ]] && LIB+=( "${P}/${I}" )
  done
done
for L in ${LIB[@]}; do echo ${L}; done

echo "--- visited libs ----------------------------------------------"
declare -a LIBDEF=()
declare -a LIBMBR=()
declare -a VISITED=()
while [[ ${#LIB[@]} -gt 0 ]]; do
  INCL=()
  for L in ${LIB[@]}; do
    LIBDEF+=($(ctags -x --kinds-c=+p-fh ${L} | grep -E -o '^[^[:space:]]+'))
    LIBMBR+=($(ctags -x --kinds-c=m ${L} | grep -E -o '^[^[:space:]]+'))
    INCL+=($(echo "$(grep -E -h '#[[:space:]]*include [<"]' ${L} \
      | sed 's/^#[[:space:]]*include [<"]\(.*\)[>"]/\1/g')"))
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
echo "${#VISITED[@]}"

echo "--- libraries definitions -------------------------------------"
LIBDEF=($(echo "${LIBDEF[@]}" | tr ' ' '\n' | sort | uniq))
echo "${#LIBDEF[@]}"

echo "--- libraries struct members ----------------------------------"
LIBMBR=($(echo "${LIBMBR[@]}" | tr ' ' '\n' | sort | uniq))
echo "${#LIBMBR[@]}"

echo "--- different user definitions found --------------------------"
declare -a USRDEF=($(find . -type f -name '*.[ch]' -exec \
  ctags -x --kinds-c=+lpzD {} ';' | grep -E -o '^[^[:space:]]+'))
echo "${#USRDEF[@]}"

echo "--- differend found words in src directory --------------------"
declare -a WORDS=($(cat src/*.c | grep -E -v '^[[:space:]]*//' \
  | grep -E -o '\b[a-zA-Z]\w*\b' | sort | uniq))
echo "${#WORDS[@]}"

echo "--- different words in char* ----------------------------------"
declare -a STRWORDS=($(grep -h -z -P -o '""|"(\n|.)*?[^\\]"' src/*.c \
  | tr '\0' '\n' | grep -E -o '\b[a-zA-Z]\w*\b' | sort | uniq))
echo "${#STRWORDS[@]}"

declare -a KEYWORDS=("auto break case char const continue default do double")
KEYWORDS+=("else enum extern float for goto if int long register return")
KEYWORDS+=("short signed sizeof static struct switch typedef union unsigned")
KEYWORDS+=("void volatile while true false ifdef ifndef endif define include")
KEYWORDS+=("undef bool")

echo "--- non user words in src -------------------------------------"
declare -a NO_USR=($(echo "${WORDS[@]} ${KEYWORDS[@]} ${KEYWORDS[@]} \
  ${USRDEF[@]} ${USRDEF[@]} ${STRWORDS[@]} ${STRWORDS[@]}" \
  | tr ' ' '\n' | sort | uniq -u))
for N in ${NO_USR[@]}; do echo ${N}; done

echo "--- undefined words in src ------------------------------------"
declare -a UNDEF=($(echo "${NO_USR[@]} ${LIBDEF[@]} ${LIBDEF[@]} \
  ${LIBMBR[@]} ${LIBMBR[@]}" | tr ' ' '\n' | sort | uniq -u))
for U in ${UNDEF[@]}; do echo ${U}; done

echo "--- undefined words not declared through lib macro ------------"
declare -a LIBMAC=()
for V in ${VISITED[@]}; do
  LIBMAC+=($(grep "^\b__MATHCALL (\b\|^\b__MATHCALLX (\b\|^\bPNG_EXPORT(\b" \
    ${V} | grep -E -o "$(echo "${UNDEF[@]}" | sed 's/ /|/g')"))
done
LIBMAC=($(echo "${UNDEF[@]} ${LIBMAC[@]}" | tr ' ' '\n' | sort | uniq -u))

declare -r RED="\e[38;5;1m"
declare -r GREEN="\e[38;5;2m"
declare -r RESET="\e[m"

[[ ${#LIBMAC[@]} -gt 0 ]] && for L in ${LIBMAC[@]}; do echo ${L}; done \
  && echo -e "${RED}EXIT WITH ERROR: Find definition for above words${RESET}" \
  && exit
[[ ${#LIBMAC[@]} -eq 0 ]] && \
  echo -e "${GREEN}Every written words in src files are known${RESET}"
