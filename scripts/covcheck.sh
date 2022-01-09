#!/usr/bin/env bash

declare -r FRAGMENTS=$(find shaders/fragment -type f)
declare -r VERTEXES=$(find shaders/vertex -type f)

make coverage > /dev/null 2>&1

declare -r SPACEPORN="./bin/cov/spaceporn"

declare -a -r ROADMAPS=($(seq 1 $(${SPACEPORN} -M))

${SPACEPORN} -h > /dev/null 2>&1
${SPACEPORN} -x -1 > /dev/null 2>&1
${SPACEPORN} -f 0 > /dev/null 2>&1
${SPACEPORN} -z 0 > /dev/null 2>&1
${SPACEPORN} -s 0 > /dev/null 2>&1
${SPACEPORN} -V -R -1 > /dev/null 2>&1
${SPACEPORN} -R 54 > /dev/null 2>&1
${SPACEPORN} -R 54 fakefile > /dev/null 2>&1

declare -r VERTEXFILE_MIN=$(${SPACEPORN} -T | tr ' ' '\n' | head -n 1)
declare -r VERTEXFILE_MAX=$(${SPACEPORN} -T | tr ' ' '\n' | tail -n 1)
declare -r FRAGMENTFILE_MIN=$(${SPACEPORN} -F | tr ' ' '\n' | head -n 1)
declare -r FRAGMENTFILE_MAX=$(${SPACEPORN} -F | tr ' ' '\n' | tail -n 1)

echo

for ROADMAP in ${ROADMAPS[@]}; do

  FLAGS=""
  if [[ ${ROADMAP} -ge ${VERTEXFILE_MIN} \
    && ${ROADMAP} -le ${VERTEXFILE_MAX} ]]; then
      FLAGS="${VERTEXES}"
  elif [[ ${ROADMAP} -ge ${FRAGMENTFILE_MIN} \
    && ${ROADMAP} -le ${FRAGMENTFILE_MAX} ]]; then
      FLAGS="${FRAGMENTS}"
  fi

  if [[ "x${FLAGS}" == "x" ]]; then
    printf %80s | tr ' ' '='
    echo -e "\n\nCovering roadmap ${ROADMAP} ..."
    ${SPACEPORN} -a -m -p -x 300 -f 30 -z 25 -R ${ROADMAP} &> /dev/null
    echo "Roadmap ${ROADMAP} covered" && echo
  else
    for FILE in ${FLAGS}; do
      printf %80s | tr ' ' '='
      echo -e "\n\nCovering roadmap ${ROADMAP} - ${FILE} ..."
      ${SPACEPORN} -a -m -p -x 300 -f 30 -z 25 -R ${ROADMAP} $(echo ${FILE} \
        | sed 's:^\([^/]\+/\)\{2\}::g') &> /dev/null
      echo "Roadmap ${ROADMAP} - ${FILE} covered" && echo
    done
  fi
done

echo -e "$(printf %80s | tr ' ' '=')\n"

SOURCES=$(find src/ -type f -not -path '*/\.*') && cd bin/cov \
  && gcov -f ${SOURCES} -o .
