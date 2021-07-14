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
  "Debug XCreateWindow() Failure"
)

PWD_DIR=$PWD
SRC_FILES=$(ls src)

for ITEM in ${SRC[@]}; do
  ITEM = $PWD_DIR/src/$ITEM
done

make coverage > /dev/null 2>&1
cd ./bin/cov

./xtelesktop -h > /dev/null 2>&1
./xtelesktop -x -1 > /dev/null 2>&1
./xtelesktop -d -1 > /dev/null 2>&1
./xtelesktop -V -R -1 > /dev/null 2>&1

echo

for ROADMAP in $(eval echo {1..$(( ${#ROADMAPS[@]} - 1 ))}); do
  echo $ROADMAP
  for I in {1..80}; do
    printf =
  done
  echo && echo
  echo "Covering ${ROADMAPS[$ROADMAP]} ..."
  ./xtelesktop -R $ROADMAP -a -m -p -x 500 -d 30000 > /dev/null 2>&1
  echo "${ROADMAPS[$ROADMAP]} covered" && echo
done

for I in {1..80}; do
  printf =
done
echo && echo

gcov -f $SRC_FILES -o .
cd $PWD_DIR
