#!/usr/bin/env bash

declare -r FRAGMENTS=$(find shaders/fragment -type f)
declare -r VERTEXES=$(find shaders/vertex -type f)

declare -a -r ROADMAPS=($(seq 2 73))

make coverage > /dev/null 2>&1

declare -r XTELESKOP="./bin/cov/xteleskop"

${XTELESKOP} -h > /dev/null 2>&1
${XTELESKOP} -x -1 > /dev/null 2>&1
${XTELESKOP} -f 0 > /dev/null 2>&1
${XTELESKOP} -z 0 > /dev/null 2>&1
${XTELESKOP} -s 0 > /dev/null 2>&1
${XTELESKOP} -s 1 -R 1 > /dev/null 2>&1
${XTELESKOP} -V -R -1 > /dev/null 2>&1
${XTELESKOP} -R 54 > /dev/null 2>&1
${XTELESKOP} -R 54 fakefile > /dev/null 2>&1

echo

for ROADMAP in ${ROADMAPS[@]}; do

  FLAGS=""
  if [[ ${ROADMAP} -ge 36 && ${ROADMAP} -le 48 ]]; then
    FLAGS="${VERTEXES}"
  elif [[ ${ROADMAP} -ge 49 && ${ROADMAP} -le 61 ]]; then
    FLAGS="${FRAGMENTS}"
  fi

  if [[ "x${FLAGS}" == "x" ]]; then
    printf %80s | tr ' ' '='
    echo -e "\n\nCovering roadmap ${ROADMAP} ..."
    ${XTELESKOP} -a -m -p -x 300 -f 30 -z 25 -R ${ROADMAP} &> /dev/null
    echo "Roadmap ${ROADMAP} covered" && echo
  else
    for FILE in ${FLAGS}; do
      printf %80s | tr ' ' '='
      echo -e "\n\nCovering roadmap ${ROADMAP} - ${FILE} ..."
      ${XTELESKOP} -a -m -p -x 300 -f 30 -z 25 -R ${ROADMAP} $(echo ${FILE} \
        | sed 's:^\([^/]\+/\)\{2\}::g') &> /dev/null
      echo "Roadmap ${ROADMAP} - ${FILE} covered" && echo
    done
  fi
done

echo -e "$(printf %80s | tr ' ' '=')\n"

SOURCES=$(find src/ -type f -not -path '*/\.*') && cd bin/cov \
  && gcov -f ${SOURCES} -o .
