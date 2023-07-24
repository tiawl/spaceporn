#! /usr/bin/env bash

cimgui_h ()
{
  # copy cimgui generated file
  cp -f "${ld}/cimgui/cimgui.h" "${ld}"

  # delete empty lines until the #endif include guard
  while [[ -z "$(tail -n 1 "${ld}/cimgui.h")" ]]
  do
    sed -i '$ d' "${ld}/cimgui.h"
  done

  # delete the #endif include guard
  sed -i '$ d' "${ld}/cimgui.h"

  # add headers needed by backends
  printf '#define GLFW_INCLUDE_NONE\n#define GLFW_INCLUDE_VULKAN\n#include <GLFW/glfw3.h>\n#include <vulkan/vulkan.h>\n' >> "${ld}/cimgui.h"

  # add the backends header file
  grep -v -E 'CIMGUI_USE_|#endif' "${ld}/cimgui/generator/output/cimgui_impl.h" | sed 's/;\(.\+\)$/;\n\1/g' | grep -E 'struct.*;|CIMGUI_API' | sed 's/^\(CIMGUI_API [^ ]* \)/\1ig/g' >> "${ld}/cimgui.h"

  # add the removed #endif include guard
  printf '#endif\n' >> "${ld}/cimgui.h"
}

cimgui_cpp ()
{
  # copy cimgui generated file and change includes
  sed 's/#\s*include\s\+"\./#include "cimgui/g' "${ld}/cimgui/cimgui.cpp" >| "${ld}/cimgui.cpp"

  # add the backends header files
  printf '#include "cimgui/imgui/backends/imgui_impl_glfw.h"\n#include "cimgui/imgui/backends/imgui_impl_vulkan.h"\n' >> "${ld}/cimgui.cpp"

  # add definition for backends functions
  local ret_type funcname args args_names
  while read -r
  do
    case "${REPLY}" in
    ( *'CIMGUI_API '* )
      REPLY="${REPLY#*CIMGUI_API }"
      ret_type="${REPLY%% *}"
      REPLY="${REPLY#* }"
      funcname="${REPLY%%(*}"
      REPLY="${REPLY#*(}"
      args="${REPLY%)*}"
      IFS=','
      set -- ${args}
      args_names="$(while [[ ${#} -gt 0 ]]
                    do
                      case "${1}" in
                      ( 'void' ) ;;
                      ( *'(*'* )
                        set -- "${1#*(\*}" "${@}"
                        printf '%s,' "${1%%)*}"
                        shift
                        while [ "${1#"${1%?}"}" != ')' ]; do shift; done ;;
                      ( * )
                        printf '%s,' "${1##* }" ;;
                      esac
                      shift
                    done)"
      IFS="${old_ifs}"
      printf 'CIMGUI_API %s ig%s(%s)\n{\n    return %s(%s);\n}\n' "${ret_type}" "${funcname}" "${args}" "${funcname}" "${args_names%,}" >> "${ld}/cimgui.cpp" ;;
    ( * ) ;;
    esac
  done < "${ld}/cimgui/generator/output/cimgui_impl.h"
}

main ()
{
  PS4='+ [e${?:-0}] '
  set -e -u -C -x
  old_ifs="${IFS}"
  ld="$(CDPATH=; cd "$(dirname "${0}")"; pwd -P)"
  readonly old_ifs ld
  cimgui_cpp
  cimgui_h
}

main "${@}"
