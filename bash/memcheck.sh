#!/bin/bash

declare -a ROADMAPS=(
  "Exit Success"
  "Break loop Success"
  "No username Failure"
  "fshaderpath malloc() Failure"
  "vshaderpath malloc() Failure"
  "texturepath malloc() Failure"
  "XOpenDisplay() Failure"
  "Invalid GLX version"
  "glXChooseFBConfig() Failure"
  "XCreateWindow() Failure"
  "Unfoundable glXCreateContextAttribsARB()"
  "Spaces in GLX extension name"
  "Unsupported GLX extension"
  "Unable to create context"
  "glewInit() Failure"
  "Vertex shader file fopen() Failure"
  "vertex_file malloc() Failure"
  "Fragment shader file fopen() Failure"
  "fragment_file malloc() Failure"
  "Unable to compile vertex shader"
  "Unable to compile fragment shader"
  "Unable to link program"
  "No PNG filename"
  "PNG file fopen() Failure"
  "png_create_read_struct() Failure"
  "png_create_info_struct() Failure"
  "png_jmpbuf() Failure"
  "Bad PNG dimensions"
  "PNG data malloc() Failure"
  "PNG row_pointers malloc() Failure"
  "OpenGL Error"
  "Debug XCreateWindow() Failure"
)

STATUS=0
EQUALS=0

echo && echo "Compiling ..." && echo
make clean all > /dev/null 2>&1

for ROADMAP in $(eval echo {1..$(( ${#ROADMAPS[@]} - 1 ))}); do

  VALGRIND_OUTPUT=$(valgrind --leak-check=summary --show-leak-kinds=all \
--suppressions=amd.supp ./bin/all/xtelesktop -a -m -p -x 500 -d 30000 \
-R $ROADMAP 2>&1 > /dev/null | sed 's/==[[:digit:]]*==/ /g')

  for ITEM in $( echo "$VALGRIND_OUTPUT" | tee \
>(grep -E -A 3 "LEAK SUMMARY") >(grep -E "ERROR SUMMARY") > /dev/null \
| grep -Po '^\D+\K(\d,?)+' | sed 's/,//g' ); do
    if [ $ITEM -ne 0 ]; then
      STATUS=1
      break
    fi
  done

  CURRENT_ROADMAP=${ROADMAPS[$ROADMAP]}

  ((EQUALS=(78 - ${#CURRENT_ROADMAP}) / 2))

  for I in $(eval echo {1..$EQUALS}); do
    printf =
  done
  printf " "
  printf "$CURRENT_ROADMAP"
  printf " "
  for I in $(eval echo {1..$EQUALS}); do
    printf =
  done
  if [ $((${#CURRENT_ROADMAP} % 2)) -eq 1 ]; then
    printf =
  fi

  echo && echo $ROADMAP && echo

  echo "$VALGRIND_OUTPUT" | grep -E -A 2 "HEAP SUMMARY" && echo
  echo "$VALGRIND_OUTPUT" | grep -E -A 5 "LEAK SUMMARY" && echo
  echo "$VALGRIND_OUTPUT" | grep -E "ERROR SUMMARY" && echo

  if [ $STATUS -ne 0 ]; then
    break
  fi

done

(exit $STATUS)
