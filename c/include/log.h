// for variadic functions
#include <stdarg.h>

// for printf()
#include <stdio.h>

// for uint32_t
#include <stdint.h>

// for malloc()
#include <stdlib.h>

// for time
#include <time.h>

// for LOGFILE
#include "build.h"

// for algol macros
#include "macros.h"

#define DEBUG_PREFIX "[" EXE " DEBUG]"
#define INFO_PREFIX  "[" EXE " INFO]"
#define ERROR_PREFIX "[" EXE " ERROR]"

#define CURRENT_TIME "%d-%02d-%02d %02d:%02d:%02d ", time_info->tm_year + 1900, time_info->tm_mon + 1, time_info->tm_mday, time_info->tm_hour, time_info->tm_min, time_info->tm_sec
#define VULKAN_LOG "[vulkan %s %s] %s\n", severity, type, vk_callback->pMessage

#define LOG(prefix, message)                                                          \
DEF                                                                                   \
  va_list args;                                                                       \
  char* expanded_message = NULL;                                                      \
  uint32_t expanded_message_len;                                                      \
                                                                                      \
  FILE* log_file = CALL fopen WITH LOGFILE, "a" ENDCALL;                              \
  IF NOT log_file                                                                     \
  THEN                                                                                \
    CALL fprintf WITH stderr, "%s fopen(%s) failed\n", ERROR_PREFIX, LOGFILE ENDCALL; \
    FAILURE;                                                                          \
  ENDIF                                                                               \
                                                                                      \
  VA_START(args, message);                                                            \
  expanded_message_len = CALL vsnprintf WITH NULL, 0, message, args ENDCALL + 1;      \
  VA_END(args);                                                                       \
                                                                                      \
  expanded_message = CALL malloc WITH sizeof(char) * expanded_message_len ENDCALL;    \
  IF NOT expanded_message                                                             \
  THEN                                                                                \
    CALL fprintf WITH stderr, "%s malloc() failed\n", ERROR_PREFIX ENDCALL;           \
    FAILURE;                                                                          \
  ENDIF                                                                               \
                                                                                      \
  VA_START(args, message);                                                            \
  CALL vsnprintf WITH expanded_message, expanded_message_len, message, args ENDCALL;  \
  VA_END(args);                                                                       \
                                                                                      \
  CALL fprintf WITH stdout, "%s %s\n", prefix, expanded_message   ENDCALL;            \
                                                                                      \
  time_t raw_time = CALL time WITH NULL ENDCALL;                                      \
  struct tm * time_info = CALL localtime WITH &raw_time ENDCALL;                      \
                                                                                      \
  CALL fprintf WITH log_file, CURRENT_TIME                        ENDCALL;            \
  CALL fprintf WITH log_file, "%s %s\n", prefix, expanded_message ENDCALL;            \
  CALL fclose  WITH log_file                                      ENDCALL;            \
  CALL free    WITH expanded_message                              ENDCALL;            \
  SUCCESS;                                                                            \
ENDDEF

PROTO debug ARGS char* message, ... ENDPROTO;
PROTO info  ARGS char* message, ... ENDPROTO;
PROTO error ARGS char* message, ... ENDPROTO;

#define ERROR(...)                                                                  \
DEF                                                                                 \
  int len = CALL snprintf WITH NULL, 0, __VA_ARGS__ ENDCALL + 1;                    \
                                                                                    \
  char * fmt = CALL malloc WITH sizeof(char) * len ENDCALL;                         \
  IF NOT fmt                                                                        \
  THEN                                                                              \
    CALL error WITH "Failed to allocate memory for 'fmt' variable" ENDCALL;         \
    FAILURE;                                                                        \
  ENDIF                                                                             \
                                                                                    \
  CALL snprintf WITH fmt, len, __VA_ARGS__ ENDCALL;                                 \
                                                                                    \
  fmt = CALL realloc WITH fmt, sizeof(char) * (len + strlen(__func__) + 4) ENDCALL; \
  IF NOT fmt                                                                        \
  THEN                                                                              \
    CALL error WITH "Failed to reallocate memory for 'fmt' variable" ENDCALL;       \
    FAILURE;                                                                        \
  ENDIF                                                                             \
                                                                                    \
  CALL memcpy WITH fmt + strlen(__func__) + 4, fmt, len ENDCALL;                    \
  CALL memcpy WITH fmt, __func__, strlen(__func__) ENDCALL;                         \
  CALL memcpy WITH fmt + strlen(__func__), "(): ", 4 ENDCALL;                       \
  CALL error WITH fmt ENDCALL;                                                      \
  CALL free WITH fmt ENDCALL;                                                       \
ENDDEF
