#ifndef TRACE_H
#define TRACE_H 1

#ifdef __cplusplus
extern "C" {
#endif

#undef TRACE_ENABLED
#ifdef TRACE_ENABLED
extern void traceFunctionCall(const char*, const char*, const char*, int, const char*, ...);
#define TRACE(fun, ...) \
    (traceFunctionCall(#fun, #__VA_ARGS__, __FILE__, __LINE__, __func__ __VA_OPT__(,) __VA_ARGS__), \
     (fun(__VA_ARGS__)))
#else
#define TRACE(fun, ...) fun(__VA_ARGS__)
#endif // TRACE_BUILD

#ifdef __cplusplus
}
#endif

#endif // TRACE_H
