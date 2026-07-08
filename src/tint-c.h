#include "spirv-tools/libspirv.h"

#ifdef __cplusplus
extern "C" {
#endif

void tintInitialize();
void tintShutdown();
int tintSPIRVReaderReadIR(const uint32_t*, size_t, void**);
void tintFreeIR(void**);
int tintWGSLWriterFromIR(void**, char**, size_t*);
int tintLastError(char** reason_ptr, size_t* reason_len);

#ifdef __cplusplus
} // extern "C"
#endif
