#define IF           if (
#define THEN         ) {
#define ELSE         } else {
#define ELIF         } else if (
#define ENDIF        }

#define FOR          for (
#define WHILE        while (
#define DO           ) {
#define DONE         }

#define SWITCH       switch (
#define IN           ) {
#define CASE         case
#define ENDCASE      break;
#define DEFAULT      default
#define ENDDEFAULT   break;
#define ENDSWITCH    }

#define FUNC         int
#define FUNC_VK      static VKAPI_ATTR VkBool32 VKAPI_CALL
#define ARGS         (
#define NOARG        )
#define PROTO        int
#define ENDPROTO     )
#define RETURN       return

#define BREAK        break
#define NEXT         continue

#define AND          &&
#define OR           ||
#define NOT          !

#define TRUE         1
#define FALSE        0
#define SUCCESS      return TRUE
#define FAILURE      return FALSE
#define FAILURE_VK   return VK_FALSE

#define CALL
#define WITH         (
#define ENDCALL      )

#define DEF          do {
#define ENDDEF       } while (FALSE)

#define STRUCT       typedef struct
#define ATTR         {
#define NAME         }
#define ENDSTRUCT

#define VA_START(args, message) va_start(args, message)
#define VA_END(args)            va_end(args)
