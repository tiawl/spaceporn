#!/usr/bin/env bash

# https://wiki.wxwidgets.org/Valgrind_Suppression_File_Howto
[[ ! -f amd.supp ]] && touch amd.supp
valgrind --leak-check=full --show-reachable=yes --error-limit=no \
  --gen-suppressions=all --log-file=minimalraw.log --suppressions=amd.supp\
  ./bin/all/xteleskop -a -m -p -x 500 -d 30000 -R ${1} ${2}
cat ./minimalraw.log | ./bash/parsesupp.sh > minimal.supp
cat minimal.supp >> amd.supp
