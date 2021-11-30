#!/bin/bash

FRAGMENTS=$(find shaders/fragment -type f)
VERTEXES=$(find shaders/vertex -type f)

declare -a ROADMAPS=($(seq 1 72))

STATUS=0
EQUALS=0

echo -e "\nCompiling ...\n"
make clean all > /dev/null 2>&1

for ROADMAP in ${ROADMAPS[@]}; do

  FLAGS=""
  if [ ${ROADMAP} -ge 35 ] && [ ${ROADMAP} -le 47 ]; then
    FLAGS="${VERTEXES}"
  elif [ ${ROADMAP} -ge 48 ] && [ ${ROADMAP} -le 60 ]; then
    FLAGS="${FRAGMENTS}"
  fi

  if [ "x${FLAGS}" = "x" ]; then
    VALGRIND_OUTPUT=$(valgrind --leak-check=summary --show-leak-kinds=all \
--suppressions=amd.supp ./bin/all/xtelesktop -a -m -p -x 500 -d 30000 \
-R ${ROADMAP} 2>&1 > /dev/null | sed 's/==[[:digit:]]*==/ /g')

    for ITEM in $( echo "$VALGRIND_OUTPUT" | tee \
>(grep -E -A 3 "LEAK SUMMARY") >(grep -E "ERROR SUMMARY") > /dev/null \
| grep -Po '^\D+\K(\d,?)+' | sed 's/,//g' ); do
      if [ ${ITEM} -ne 0 ]; then
        STATUS=1
        break
      fi
    done

    ((EQUALS=(78 - ${#ROADMAP}) / 2))

    printf %${EQUALS}s | tr ' ' '='
    printf " "
    printf "${ROADMAP}"
    printf " "
    printf %${EQUALS}s | tr ' ' '='
    if [ $((${#ROADMAP} % 2)) -eq 1 ]; then
      printf =
    fi

    echo -e "\n"

    echo "${VALGRIND_OUTPUT}" | grep -E -A 2 "HEAP SUMMARY" && echo
    echo "${VALGRIND_OUTPUT}" | grep -E -A 5 "LEAK SUMMARY" && echo
    echo "${VALGRIND_OUTPUT}" | grep -E "ERROR SUMMARY" && echo

    if [ ${STATUS} -ne 0 ]; then
      break
    fi
  else
    for ${FILE} in ${FLAGS}; do
      VALGRIND_OUTPUT=$(valgrind --leak-check=summary --show-leak-kinds=all \
--suppressions=amd.supp ./bin/all/xtelesktop -a -m -p -x 500 -d 30000 \
-R ${ROADMAP} ${FILE} 2>&1 > /dev/null | sed 's/==[[:digit:]]*==/ /g')

      for ITEM in $( echo "$VALGRIND_OUTPUT" | tee \
>(grep -E -A 3 "LEAK SUMMARY") >(grep -E "ERROR SUMMARY") > /dev/null \
| grep -Po '^\D+\K(\d,?)+' | sed 's/,//g' ); do
        if [ ${ITEM} -ne 0 ]; then
          STATUS=1
          break
        fi
      done

      ((EQUALS=(78 - ${#ROADMAP} - ${#FILE} - 2) / 2))

      printf %${EQUALS}s | tr ' ' '='
      printf " "
      printf "${ROADMAP}: ${FILE}"
      printf " "
      printf %${EQUALS}s | tr ' ' '='
      if [ $(((${#ROADMAP} + ${#FILE}) % 2)) -eq 1 ]; then
        printf =
      fi

      echo -e "\n${VALGRIND_OUTPUT}" | grep -E -A 2 "HEAP SUMMARY" && echo
      echo "${VALGRIND_OUTPUT}" | grep -E -A 5 "LEAK SUMMARY" && echo
      echo "${VALGRIND_OUTPUT}" | grep -E "ERROR SUMMARY" && echo

      if [ ${STATUS} -ne 0 ]; then
        break
      fi
    done
  fi

done

(exit ${STATUS})
