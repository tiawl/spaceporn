#! /usr/bin/env bash

main ()
{
  PS4='+ [e${?:-0}] '
  set -e -u -C -x
  old_ifs="${IFS}"
  ld="$(CDPATH=; cd "$(dirname "${0}")"; pwd -P)"
  readonly old_ifs ld
  python3 "${ld}/dear_bindings/dear_bindings.py" --output "${ld}/cimgui" "${ld}/imgui/imgui.h"
  python3 "${ld}/dear_bindings/dear_bindings.py" --backend --output "${ld}/cimgui_impl_vulkan" "${ld}/imgui/backends/imgui_impl_vulkan.h"
  python3 "${ld}/dear_bindings/dear_bindings.py" --backend --output "${ld}/cimgui_impl_glfw"   "${ld}/imgui/backends/imgui_impl_glfw.h"
  rm -f "${ld}"/*.json
}

main "${@}"
