#!/usr/bin/env bash

PWD_DIR=$PWD

mkdir -p bin/conf
cp conf/configure bin/conf
cd bin/conf
./configure
rm configure
cd $PWD_DIR
