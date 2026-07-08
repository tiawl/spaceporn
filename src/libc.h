#ifndef LIBC_H
#define LIBC_H 1

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#include "trace.h"

#undef  LIBC_H_ASSERT
#undef  LIBC_H_CTYPE
#undef  LIBC_H_INTTYPES
#undef  LIBC_H_MATH
#undef  LIBC_H_STDIO
#undef  LIBC_H_STDLIB
#undef  LIBC_H_STRING
#undef  LIBC_H_SYS_WAIT
#undef  LIBC_H_TIME
#undef  LIBC_H_UNISTD

extern int errno;

#if     LIBC_H_ASSERT

extern void     libcImpl_assertFail(const char*, const char*, int, const char*);

#define assert(x)      ((void)((x) || (libcImpl_assertFail(#x, __FILE__, __LINE__, __func__),0)))

#endif  // LIBC_H_ASSERT
#if     LIBC_H_CTYPE

extern int      libcImpl_toupper(int);

#define toupper(...)   TRACE(libcImpl_toupper, __VA_ARGS__)

#endif  // LIBC_H_CTYPE
#if     LIBC_H_INTTYPES

#if     UINTPTR_MAX == UINT64_MAX
#define __PRI64  "l"
#else
#define __PRI64  "ll"
#endif  // UINTPTR_MAX == UINT64_MAX

#define PRId64 __PRI64 "d"
#define PRIu64 __PRI64 "u"

#endif  // LIBC_H_INTTYPES
#if     LIBC_H_MATH

extern double   libcImpl_acos(double);
extern float    libcImpl_acosf(float);
extern float    libcImpl_atan2f(float, float);
extern float    libcImpl_ceilf(float);
extern double   libcImpl_cos(double);
extern float    libcImpl_cosf(float);
extern double   libcImpl_fabs(double);
extern float    libcImpl_fabsf(float);
extern float    libcImpl_floorf(float);
extern float    libcImpl_fmodf(float, float);
extern double   libcImpl_log(double);
extern float    libcImpl_logf(float);
extern double   libcImpl_pow(double, double);
extern float    libcImpl_powf(float, float);
extern float    libcImpl_sinf(float);
extern double   libcImpl_sqrt(double);
extern float    libcImpl_sqrtf(float);

#define acos(...)      TRACE(libcImpl_acos, __VA_ARGS__)
#define acosf(...)     TRACE(libcImpl_acosf, __VA_ARGS__)
#define atan2f(...)    TRACE(libcImpl_atan2f, __VA_ARGS__)
#define ceilf(...)     TRACE(libcImpl_ceilf, __VA_ARGS__)
#define cos(...)       TRACE(libcImpl_cos, __VA_ARGS__)
#define cosf(...)      TRACE(libcImpl_cosf, __VA_ARGS__)
#define fabs(...)      TRACE(libcImpl_fabs, __VA_ARGS__)
#define fabsf(...)     TRACE(libcImpl_fabsf, __VA_ARGS__)
#define floorf(...)    TRACE(libcImpl_floorf, __VA_ARGS__)
#define fmodf(...)     TRACE(libcImpl_fmodf, __VA_ARGS__)
#define log(...)       TRACE(libcImpl_log, __VA_ARGS__)
#define logf(...)      TRACE(libcImpl_logf, __VA_ARGS__)
#define pow(...)       TRACE(libcImpl_pow, __VA_ARGS__)
#define powf(...)      TRACE(libcImpl_powf, __VA_ARGS__)
#define sinf(...)      TRACE(libcImpl_sinf, __VA_ARGS__)
#define sqrt(...)      TRACE(libcImpl_sqrt, __VA_ARGS__)
#define sqrtf(...)     TRACE(libcImpl_sqrtf, __VA_ARGS__)

#endif  // LIBC_H_MATH
#if     LIBC_H_STDIO || LIBC_H_UNISTD

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#endif  // LIBC_H_STDIO || LIBC_H_UNISTD
#if     LIBC_H_STDIO

struct FILEImpl;
typedef struct FILEImpl* FILE;

static FILE stdin_file;
static FILE stdout_file;
static FILE stderr_file;

#define stdin &stdin_file
#define stdout &stdout_file
#define stderr &stderr_file

extern double   libcImpl_atof(const char*);
extern int      libcImpl_fclose(FILE*);
extern int      libcImpl_fflush(FILE*);
extern FILE*    libcImpl_fopen(const char*, const char*);
extern int      libcImpl_fprintf(FILE*, const char*, ...);
extern size_t   libcImpl_fread(void*, size_t, size_t, FILE*);
extern void     libcImpl_free(void*);
extern int      libcImpl_fseek(FILE*, long int, int);
extern long int libcImpl_ftell(FILE*);
extern size_t   libcImpl_fwrite(const void*, size_t, size_t, FILE*);
extern void*    libcImpl_malloc(size_t);
extern int      libcImpl_snprintf(char*, size_t, const char*, ...);
extern int      libcImpl_sprintf(char*, const char*, ...);
extern int      libcImpl_sscanf(const char*, const char*, ...);
extern int      libcImpl_vsnprintf(char*, size_t, const char*, va_list);
extern int      libcImpl_vsprintf(char*, const char*, va_list);

#define atof(...)      TRACE(libcImpl_atof, __VA_ARGS__)
#define fclose(...)    TRACE(libcImpl_fclose, __VA_ARGS__)
#define fflush(...)    TRACE(libcImpl_fflush, __VA_ARGS__)
#define fopen(...)     TRACE(libcImpl_fopen, __VA_ARGS__)
#define fread(...)     TRACE(libcImpl_fread, __VA_ARGS__)
#define free(...)      TRACE(libcImpl_free, __VA_ARGS__)
#define fseek(...)     TRACE(libcImpl_fseek, __VA_ARGS__)
#define ftell(...)     TRACE(libcImpl_ftell, __VA_ARGS__)
#define fwrite(...)    TRACE(libcImpl_fwrite, __VA_ARGS__)
#define malloc(...)    TRACE(libcImpl_malloc, __VA_ARGS__)
#define printf(...)    TRACE(libcImpl_fprintf, stdout, __VA_ARGS__)
#define snprintf(...)  TRACE(libcImpl_snprintf, __VA_ARGS__)
#define sprintf(...)   TRACE(libcImpl_sprintf, __VA_ARGS__)
#define sscanf(...)    TRACE(libcImpl_sscanf, __VA_ARGS__)
#define vsnprintf(...) TRACE(libcImpl_vsnprintf, __VA_ARGS__)
#define vsprintf(...)  TRACE(libcImpl_vsprintf, __VA_ARGS__)

#endif  // LIBC_H_STDIO
#if     LIBC_H_STDLIB || LIBC_H_SYS_WAIT

#define WEXITSTATUS(s) (((s) & 0xff00) >> 8)

#endif  // LIBC_H_SYS_WAIT || LIBC_H_STDLIB
#if     LIBC_H_STDLIB

typedef struct {
  long int quot;
  long int rem;
} ldiv_t;

extern void     libcImpl_exit(int);
extern void     libcImpl_qsort(void*, size_t, size_t, int (*)(const void*, const void*));

#define exit(...)      TRACE(libcImpl_exit, __VA_ARGS__)
#define qsort(...)     TRACE(libcImpl_qsort, __VA_ARGS__)

#endif  // LIBC_H_STDLIB
#if     LIBC_H_STRING

extern void*    libcImpl_memchr(const void*, int, size_t);
extern int      libcImpl_memcmp(const void*, const void*, size_t);
extern void*    libcImpl_memcpy(void*, const void*, size_t);
extern void*    libcImpl_memmove(void*, const void*, size_t);
extern void*    libcImpl_memset(void*, char, size_t);
extern char*    libcImpl_strchr(const char*, int);
extern int      libcImpl_strcmp(const char*, const char*);
extern char*    libcImpl_strcpy(char*, const char*);
extern int      libcImpl_strncmp(const char*, const char*, size_t);
extern char*    libcImpl_strncpy(char*, const char*, size_t);
extern int      libcImpl_strlen(const char*);
extern char*    libcImpl_strstr(const char*, const char*);

#define memchr(...)    TRACE(libcImpl_memchr, __VA_ARGS__)
#define memcmp(...)    TRACE(libcImpl_memcmp, __VA_ARGS__)
#define memcpy(...)    TRACE(libcImpl_memcpy, __VA_ARGS__)
#define memmove(...)   TRACE(libcImpl_memmove, __VA_ARGS__)
#define memset(...)    TRACE(libcImpl_memset, __VA_ARGS__)
#define strchr(...)    TRACE(libcImpl_strchr, __VA_ARGS__)
#define strcmp(...)    TRACE(libcImpl_strcmp, __VA_ARGS__)
#define strcpy(...)    TRACE(libcImpl_strcpy, __VA_ARGS__)
#define strncmp(...)   TRACE(libcImpl_strncmp, __VA_ARGS__)
#define strncpy(...)   TRACE(libcImpl_strncpy, __VA_ARGS__)
#define strlen(...)    TRACE(libcImpl_strlen, __VA_ARGS__)
#define strstr(...)    TRACE(libcImpl_strstr, __VA_ARGS__)

#endif  // LIBC_H_STRING
#if     LIBC_H_TIME

typedef long time_t;

// tm_sec, tm_min, tm_hour, tm_wday, tm_yday, tm_isdst, tm_gmtoff and tm_zone aren't necessary to implement
typedef struct tm {
    int tm_mday;
    int tm_mon;
    int tm_year;
} tm;

extern tm*      libcImpl_localtime_r(const time_t*, tm*);
extern time_t   libcImpl_time(time_t*);

#define localtime_r(...) TRACE(libcImpl_localtime_r, __VA_ARGS__)
#define time(...)        TRACE(libcImpl_time, __VA_ARGS__)

#endif  // LIBC_H_TIME
#if     LIBC_H_SYS_WAIT || LIBC_H_UNISTD

typedef int pid_t;

#endif  // LIBC_H_SYS_WAIT || LIBC_H_UNISTD
#if     LIBC_H_SYS_WAIT

extern pid_t    libcImpl_waitpid(pid_t, int*, int);

#define waitpid(...)   TRACE(libcImpl_waitpid, __VA_ARGS__)

#endif  // LIBC_H_SYS_WAIT
#if     LIBC_H_UNISTD

typedef unsigned useconds_t;

extern int      libcImpl_execvp(const char*, char* const[]);
extern pid_t    libcImpl_fork();
extern int      libcImpl_usleep(useconds_t);

#define execvp(...)    TRACE(libcImpl_execvp, __VA_ARGS__)
#define fork(...)      TRACE(libcImpl_fork, __VA_ARGS__)
#define usleep(...)    TRACE(libcImpl_usleep, __VA_ARGS__)

#endif  // LIBC_H_UNISTD

#ifdef __cplusplus
}
#endif

#endif // LIBC_H
