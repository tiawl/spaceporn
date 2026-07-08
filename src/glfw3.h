#ifndef GLFW3_H
#define GLFW3_H 1

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>

#undef  GLFW3_H_MACROS
#undef  GLFW3_H_IMPL
#undef  GLFW3_H_STRUCTS
#undef  GLFW3_H_FUNCS

#if     GLFW3_H_MACROS

#define GLFW_FALSE                  0
#define GLFW_TRUE                   1

#define GLFW_FOCUSED                0x00020001

#define GLFW_CURSOR                 0x00033001

#define GLFW_CURSOR_NORMAL          0x00034001
#define GLFW_CURSOR_HIDDEN          0x00034002
#define GLFW_CURSOR_DISABLED        0x00034003

#define GLFW_ARROW_CURSOR           0x00036001
#define GLFW_IBEAM_CURSOR           0x00036002
#define GLFW_CROSSHAIR_CURSOR       0x00036003
#define GLFW_POINTING_HAND_CURSOR   0x00036004
#define GLFW_RESIZE_EW_CURSOR       0x00036005
#define GLFW_RESIZE_NS_CURSOR       0x00036006
#define GLFW_RESIZE_NWSE_CURSOR     0x00036007
#define GLFW_RESIZE_NESW_CURSOR     0x00036008
#define GLFW_RESIZE_ALL_CURSOR      0x00036009
#define GLFW_NOT_ALLOWED_CURSOR     0x0003600A

#define GLFW_HRESIZE_CURSOR         GLFW_RESIZE_EW_CURSOR
#define GLFW_VRESIZE_CURSOR         GLFW_RESIZE_NS_CURSOR
#define GLFW_HAND_CURSOR            GLFW_POINTING_HAND_CURSOR

#define GLFW_VERSION_MAJOR          3
#define GLFW_VERSION_MINOR          5
#define GLFW_VERSION_REVISION       1

#define GLFW_RELEASE                0
#define GLFW_PRESS                  1

/* Printable keys */
#define GLFW_KEY_UNKNOWN            -1
#define GLFW_KEY_SPACE              32
#define GLFW_KEY_APOSTROPHE         39  /* ' */
#define GLFW_KEY_COMMA              44  /* , */
#define GLFW_KEY_MINUS              45  /* - */
#define GLFW_KEY_PERIOD             46  /* . */
#define GLFW_KEY_SLASH              47  /* / */
#define GLFW_KEY_0                  48
#define GLFW_KEY_1                  49
#define GLFW_KEY_2                  50
#define GLFW_KEY_3                  51
#define GLFW_KEY_4                  52
#define GLFW_KEY_5                  53
#define GLFW_KEY_6                  54
#define GLFW_KEY_7                  55
#define GLFW_KEY_8                  56
#define GLFW_KEY_9                  57
#define GLFW_KEY_SEMICOLON          59  /* ; */
#define GLFW_KEY_EQUAL              61  /* = */
#define GLFW_KEY_A                  65
#define GLFW_KEY_B                  66
#define GLFW_KEY_C                  67
#define GLFW_KEY_D                  68
#define GLFW_KEY_E                  69
#define GLFW_KEY_F                  70
#define GLFW_KEY_G                  71
#define GLFW_KEY_H                  72
#define GLFW_KEY_I                  73
#define GLFW_KEY_J                  74
#define GLFW_KEY_K                  75
#define GLFW_KEY_L                  76
#define GLFW_KEY_M                  77
#define GLFW_KEY_N                  78
#define GLFW_KEY_O                  79
#define GLFW_KEY_P                  80
#define GLFW_KEY_Q                  81
#define GLFW_KEY_R                  82
#define GLFW_KEY_S                  83
#define GLFW_KEY_T                  84
#define GLFW_KEY_U                  85
#define GLFW_KEY_V                  86
#define GLFW_KEY_W                  87
#define GLFW_KEY_X                  88
#define GLFW_KEY_Y                  89
#define GLFW_KEY_Z                  90
#define GLFW_KEY_LEFT_BRACKET       91  /* [ */
#define GLFW_KEY_BACKSLASH          92  /* \ */
#define GLFW_KEY_RIGHT_BRACKET      93  /* ] */
#define GLFW_KEY_GRAVE_ACCENT       96  /* ` */
#define GLFW_KEY_WORLD_1            161 /* non-US #1 */
#define GLFW_KEY_WORLD_2            162 /* non-US #2 */

/* Function keys */
#define GLFW_KEY_ESCAPE             256
#define GLFW_KEY_ENTER              257
#define GLFW_KEY_TAB                258
#define GLFW_KEY_BACKSPACE          259
#define GLFW_KEY_INSERT             260
#define GLFW_KEY_DELETE             261
#define GLFW_KEY_RIGHT              262
#define GLFW_KEY_LEFT               263
#define GLFW_KEY_DOWN               264
#define GLFW_KEY_UP                 265
#define GLFW_KEY_PAGE_UP            266
#define GLFW_KEY_PAGE_DOWN          267
#define GLFW_KEY_HOME               268
#define GLFW_KEY_END                269
#define GLFW_KEY_CAPS_LOCK          280
#define GLFW_KEY_SCROLL_LOCK        281
#define GLFW_KEY_NUM_LOCK           282
#define GLFW_KEY_PRINT_SCREEN       283
#define GLFW_KEY_PAUSE              284
#define GLFW_KEY_F1                 290
#define GLFW_KEY_F2                 291
#define GLFW_KEY_F3                 292
#define GLFW_KEY_F4                 293
#define GLFW_KEY_F5                 294
#define GLFW_KEY_F6                 295
#define GLFW_KEY_F7                 296
#define GLFW_KEY_F8                 297
#define GLFW_KEY_F9                 298
#define GLFW_KEY_F10                299
#define GLFW_KEY_F11                300
#define GLFW_KEY_F12                301
#define GLFW_KEY_F13                302
#define GLFW_KEY_F14                303
#define GLFW_KEY_F15                304
#define GLFW_KEY_F16                305
#define GLFW_KEY_F17                306
#define GLFW_KEY_F18                307
#define GLFW_KEY_F19                308
#define GLFW_KEY_F20                309
#define GLFW_KEY_F21                310
#define GLFW_KEY_F22                311
#define GLFW_KEY_F23                312
#define GLFW_KEY_F24                313
#define GLFW_KEY_F25                314
#define GLFW_KEY_KP_0               320
#define GLFW_KEY_KP_1               321
#define GLFW_KEY_KP_2               322
#define GLFW_KEY_KP_3               323
#define GLFW_KEY_KP_4               324
#define GLFW_KEY_KP_5               325
#define GLFW_KEY_KP_6               326
#define GLFW_KEY_KP_7               327
#define GLFW_KEY_KP_8               328
#define GLFW_KEY_KP_9               329
#define GLFW_KEY_KP_DECIMAL         330
#define GLFW_KEY_KP_DIVIDE          331
#define GLFW_KEY_KP_MULTIPLY        332
#define GLFW_KEY_KP_SUBTRACT        333
#define GLFW_KEY_KP_ADD             334
#define GLFW_KEY_KP_ENTER           335
#define GLFW_KEY_KP_EQUAL           336
#define GLFW_KEY_LEFT_SHIFT         340
#define GLFW_KEY_LEFT_CONTROL       341
#define GLFW_KEY_LEFT_ALT           342
#define GLFW_KEY_LEFT_SUPER         343
#define GLFW_KEY_RIGHT_SHIFT        344
#define GLFW_KEY_RIGHT_CONTROL      345
#define GLFW_KEY_RIGHT_ALT          346
#define GLFW_KEY_RIGHT_SUPER        347
#define GLFW_KEY_MENU               348
#define GLFW_KEY_LAST               GLFW_KEY_MENU

#define GLFW_JOYSTICK_1             0

#define GLFW_GAMEPAD_BUTTON_A               0
#define GLFW_GAMEPAD_BUTTON_B               1
#define GLFW_GAMEPAD_BUTTON_X               2
#define GLFW_GAMEPAD_BUTTON_Y               3
#define GLFW_GAMEPAD_BUTTON_LEFT_BUMPER     4
#define GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER    5
#define GLFW_GAMEPAD_BUTTON_BACK            6
#define GLFW_GAMEPAD_BUTTON_START           7
#define GLFW_GAMEPAD_BUTTON_GUIDE           8
#define GLFW_GAMEPAD_BUTTON_LEFT_THUMB      9
#define GLFW_GAMEPAD_BUTTON_RIGHT_THUMB     10
#define GLFW_GAMEPAD_BUTTON_DPAD_UP         11
#define GLFW_GAMEPAD_BUTTON_DPAD_RIGHT      12
#define GLFW_GAMEPAD_BUTTON_DPAD_DOWN       13
#define GLFW_GAMEPAD_BUTTON_DPAD_LEFT       14
#define GLFW_GAMEPAD_BUTTON_LAST            GLFW_GAMEPAD_BUTTON_DPAD_LEFT

#define GLFW_GAMEPAD_BUTTON_CROSS       GLFW_GAMEPAD_BUTTON_A
#define GLFW_GAMEPAD_BUTTON_CIRCLE      GLFW_GAMEPAD_BUTTON_B
#define GLFW_GAMEPAD_BUTTON_SQUARE      GLFW_GAMEPAD_BUTTON_X
#define GLFW_GAMEPAD_BUTTON_TRIANGLE    GLFW_GAMEPAD_BUTTON_Y

#define GLFW_GAMEPAD_AXIS_LEFT_X        0
#define GLFW_GAMEPAD_AXIS_LEFT_Y        1
#define GLFW_GAMEPAD_AXIS_RIGHT_X       2
#define GLFW_GAMEPAD_AXIS_RIGHT_Y       3
#define GLFW_GAMEPAD_AXIS_LEFT_TRIGGER  4
#define GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER 5
#define GLFW_GAMEPAD_AXIS_LAST          GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER

#define GLFW_NO_ERROR               0

#endif  // GLFW3_H_MACROS
#if     GLFW3_H_IMPL

typedef struct GLFWwindow GLFWwindow;
typedef struct GLFWmonitor GLFWmonitor;
typedef struct GLFWcursor GLFWcursor;

#endif  // GLFW3_H_IMPL
#if     GLFW3_H_STRUCTS

typedef struct GLFWgamepadstate {
    unsigned char buttons[15];
    float axes[6];
} GLFWgamepadstate;

typedef void (* GLFWwindowfocusfun)(GLFWwindow*, int);
typedef void (* GLFWcursorposfun)(GLFWwindow*, double, double);
typedef void (* GLFWcursorenterfun)(GLFWwindow*, int);
typedef void (* GLFWmousebuttonfun)(GLFWwindow*, int, int, int);
typedef void (* GLFWscrollfun)(GLFWwindow*, double, double);
typedef void (* GLFWkeyfun)(GLFWwindow*, int, int, int, int);
typedef void (* GLFWcharfun)(GLFWwindow*, unsigned int);
typedef void (* GLFWmonitorfun)(GLFWmonitor*, int);
typedef void (* GLFWerrorfun)(int, const char*);

#endif  // GLFW3_H_STRUCTS
#if     GLFW3_H_FUNCS

extern GLFWwindowfocusfun glfw3Impl_setWindowFocusCallback(GLFWwindow*, GLFWwindowfocusfun);
extern GLFWcursorposfun   glfw3Impl_setCursorPosCallback(GLFWwindow*, GLFWcursorposfun);
extern GLFWcursorenterfun glfw3Impl_setCursorEnterCallback(GLFWwindow*, GLFWcursorenterfun);
extern GLFWmousebuttonfun glfw3Impl_setMouseButtonCallback(GLFWwindow*, GLFWmousebuttonfun);
extern GLFWscrollfun      glfw3Impl_setScrollCallback(GLFWwindow*, GLFWscrollfun);
extern GLFWkeyfun         glfw3Impl_setKeyCallback(GLFWwindow*, GLFWkeyfun);
extern GLFWcharfun        glfw3Impl_setCharCallback(GLFWwindow*, GLFWcharfun);
extern GLFWmonitorfun     glfw3Impl_setMonitorCallback(GLFWmonitorfun);
extern GLFWerrorfun       glfw3Impl_setErrorCallback(GLFWerrorfun);
extern const char*        glfw3Impl_getClipboardString(GLFWwindow*);
extern void               glfw3Impl_setClipboardString(GLFWwindow*, const char*);
extern void               glfw3Impl_setCursor(GLFWwindow*, GLFWcursor*);
extern void               glfw3Impl_getCursorPos(GLFWwindow*, double*, double*);
extern void               glfw3Impl_setCursorPos(GLFWwindow*, double, double);
extern int                glfw3Impl_getKey(GLFWwindow*, int);
extern const char*        glfw3Impl_getKeyName(int, int);
extern int                glfw3Impl_getError(const char**);
extern GLFWcursor*        glfw3Impl_createStandardCursor(int);
extern void               glfw3Impl_destroyCursor(GLFWcursor*);
extern int                glfw3Impl_getWindowAttrib(GLFWwindow*, int);
extern int                glfw3Impl_getInputMode(GLFWwindow*, int);
extern void               glfw3Impl_setInputMode(GLFWwindow*, int, int);
extern int                glfw3Impl_getGamepadState(int, GLFWgamepadstate*);
extern void               glfw3Impl_getWindowContentScale(GLFWwindow*, float*, float*);
extern void               glfw3Impl_getMonitorContentScale(GLFWmonitor*, float*, float*);
extern void               glfw3Impl_getWindowSize(GLFWwindow*, int*, int*);
extern void               glfw3Impl_getFramebufferSize(GLFWwindow*, int*, int*);
extern double             glfw3Impl_getTime();

#include "trace.h"

#define glfwSetWindowFocusCallback(...) TRACE(glfw3Impl_setWindowFocusCallback, __VA_ARGS__)
#define glfwSetCursorPosCallback(...)   TRACE(glfw3Impl_setCursorPosCallback, __VA_ARGS__)
#define glfwSetCursorEnterCallback(...) TRACE(glfw3Impl_setCursorEnterCallback, __VA_ARGS__)
#define glfwSetMouseButtonCallback(...) TRACE(glfw3Impl_setMouseButtonCallback, __VA_ARGS__)
#define glfwSetScrollCallback(...)      TRACE(glfw3Impl_setScrollCallback, __VA_ARGS__)
#define glfwSetKeyCallback(...)         TRACE(glfw3Impl_setKeyCallback, __VA_ARGS__)
#define glfwSetCharCallback(...)        TRACE(glfw3Impl_setCharCallback, __VA_ARGS__)
#define glfwSetMonitorCallback(...)     TRACE(glfw3Impl_setMonitorCallback, __VA_ARGS__)
#define glfwSetErrorCallback(...)       TRACE(glfw3Impl_setErrorCallback, __VA_ARGS__)
#define glfwGetClipboardString(...)     TRACE(glfw3Impl_getClipboardString, __VA_ARGS__)
#define glfwSetClipboardString(...)     TRACE(glfw3Impl_setClipboardString, __VA_ARGS__)
#define glfwSetCursor(...)              TRACE(glfw3Impl_setCursor, __VA_ARGS__)
#define glfwGetCursorPos(...)           TRACE(glfw3Impl_getCursorPos, __VA_ARGS__)
#define glfwSetCursorPos(...)           TRACE(glfw3Impl_setCursorPos, __VA_ARGS__)
#define glfwGetKey(...)                 TRACE(glfw3Impl_getKey, __VA_ARGS__)
#define glfwGetKeyName(...)             TRACE(glfw3Impl_getKeyName, __VA_ARGS__)
#define glfwGetError(...)               TRACE(glfw3Impl_getError, __VA_ARGS__)
#define glfwCreateStandardCursor(...)   TRACE(glfw3Impl_createStandardCursor, __VA_ARGS__)
#define glfwDestroyCursor(...)          TRACE(glfw3Impl_destroyCursor, __VA_ARGS__)
#define glfwGetWindowAttrib(...)        TRACE(glfw3Impl_getWindowAttrib, __VA_ARGS__)
#define glfwGetInputMode(...)           TRACE(glfw3Impl_getInputMode, __VA_ARGS__)
#define glfwSetInputMode(...)           TRACE(glfw3Impl_setInputMode, __VA_ARGS__)
#define glfwGetGamepadState(...)        TRACE(glfw3Impl_getGamepadState, __VA_ARGS__)
#define glfwGetWindowContentScale(...)  TRACE(glfw3Impl_getWindowContentScale, __VA_ARGS__)
#define glfwGetMonitorContentScale(...) TRACE(glfw3Impl_getMonitorContentScale, __VA_ARGS__)
#define glfwGetWindowSize(...)          TRACE(glfw3Impl_getWindowSize, __VA_ARGS__)
#define glfwGetFramebufferSize(...)     TRACE(glfw3Impl_getFramebufferSize, __VA_ARGS__)
#define glfwGetTime(...)                TRACE(glfw3Impl_getTime, __VA_ARGS__)

#endif  // GLFW3_H_FUNCS

#ifdef __cplusplus
}
#endif

#endif // GLFW3_H
