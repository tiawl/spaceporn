#!/usr/bin/env bash

declare -r FRAGMENTS=$(find shaders/fragment -type f)
declare -r VERTEXES=$(find shaders/vertex -type f)

declare -a -r ROADMAPS=($(seq 1 72))

STATUS=0
EQUALS=0

echo -e "\nCompiling ...\n"
make clean all > /dev/null 2>&1

for ROADMAP in ${ROADMAPS[@]}; do

  FLAGS=""
  if [[ ${ROADMAP} -ge 35 && ${ROADMAP} -le 47 ]]; then
    FLAGS="${VERTEXES}"
  elif [[ ${ROADMAP} -ge 48 && ${ROADMAP} -le 60 ]]; then
    FLAGS="${FRAGMENTS}"
  fi

  if [[ "x${FLAGS}" == "x" ]]; then
    VALGRIND_OUTPUT=$(valgrind --leak-check=summary --show-leak-kinds=all \
      --suppressions=amd.supp ./bin/all/xteleskop -a -m -p -x 500 -d 30000 \
      -R ${ROADMAP} 2>&1 > /dev/null | sed 's/==[[:digit:]]*==/ /g')

    [[ $(echo "${VALGRIND_OUTPUT}" | tee >(grep -E -A 4 "LEAK SUMMARY") \
      >(grep -E "ERROR SUMMARY") > /dev/null | grep -Po '^\D*\K(\d,?)+' \
      | tr -d ',' | grep -E -v "^0$" | wc -l) -gt 0 ]] && STATUS=1

    EQUALS=$(( (80 - ${#ROADMAP} - 2) / 2 ))

    BAR=$(printf %${EQUALS}s | tr ' ' '=')
    printf "${BAR} ${ROADMAP} ${BAR}"
    [[ $(( ${#ROADMAP} % 2 )) -eq 1 ]] && printf "="

    echo -e "\n\n$(echo "${VALGRIND_OUTPUT}" | grep -E -A 2 "HEAP SUMMARY")\n"
    [[ "${VALGRIND_OUTPUT}" =~ LEAK\ SUMMARY ]] && echo -e "$( \
      echo "${VALGRIND_OUTPUT}" | grep -E -A 5 "LEAK SUMMARY")\n"
    echo -e "$(echo "${VALGRIND_OUTPUT}" | grep -E "ERROR SUMMARY")\n"

    [[ ${STATUS} -ne 0 ]] && exit 1
  else
    for FILE in ${FLAGS}; do
      VALGRIND_OUTPUT=$(valgrind --leak-check=summary --show-leak-kinds=all \
        --suppressions=amd.supp ./bin/all/xteleskop -a -m -p -x 500 -d 30000 \
        -R ${ROADMAP} $(echo ${FILE} | sed 's:^\([^/]\+/\)\{2\}::g') 2>&1 \
        > /dev/null | sed 's/==[[:digit:]]*==/ /g')

      [[ $(echo "${VALGRIND_OUTPUT}" | tee >(grep -E -A 4 "LEAK SUMMARY") \
        >(grep -E "ERROR SUMMARY") > /dev/null | grep -Po '^\D*\K(\d,?)+' \
        | tr -d ',' | grep -E -v "^0$" | wc -l) -gt 0 ]] && STATUS=1

      EQUALS=$(( (80 - ${#ROADMAP} - ${#FILE} - 5) / 2 ))

      BAR=$(printf %${EQUALS}s | tr ' ' '=')
      printf "${BAR} ${ROADMAP} - ${FILE} ${BAR}"
      [[ $(( (${#ROADMAP} + ${#FILE} + 3) % 2 )) -eq 1 ]] && printf "="

      echo -e "\n\n$(echo "${VALGRIND_OUTPUT}" | grep -E -A 2 "HEAP SUMMARY")\n"
      [[ "${VALGRIND_OUTPUT}" =~ LEAK\ SUMMARY ]] && echo -e "$( \
        echo "${VALGRIND_OUTPUT}" | grep -E -A 5 "LEAK SUMMARY")\n"
      echo -e "$(echo "${VALGRIND_OUTPUT}" | grep -E "ERROR SUMMARY")\n"

      [[ ${STATUS} -ne 0 ]] && exit 1
    done
  fi
done
