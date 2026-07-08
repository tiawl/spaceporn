#include "src/tint/api/tint.h"
#include "src/tint/utils/result.h"
#include "src/tint/lang/core/ir/module.h"
#include "src/tint/lang/spirv/reader/reader.h"
#include "src/tint/lang/wgsl/writer/writer.h"
#include "src/tint/lang/wgsl/writer/output.h"
#include <cstdlib>
#include <cstring>
#include <vector>
#include <string>

namespace {
    std::string g_last_error;

    void setLastError(const std::string& str) {
        g_last_error = str;
    }

    void clearLastError() {
        g_last_error.clear();
    }

    const char* getLastErrorData() {
        return g_last_error.data();
    }

    size_t getLastErrorSize() {
        return g_last_error.size();
    }

    bool isLastErrorEmpty() {
        return g_last_error.empty();
    }
}

#ifdef __cplusplus
extern "C" {
#endif

void tintInitialize() {
    clearLastError();
    tint::Initialize();
}

void tintShutdown() {
    tint::Shutdown();
}

int tintLastError(char** reason_ptr, size_t* reason_len) {
    if (!reason_ptr || !reason_len) return 1;

    if (isLastErrorEmpty()) {
        *reason_ptr = nullptr;
        *reason_len = 0;
        return 0;
    }

    char* buf = static_cast<char*>(std::malloc(getLastErrorSize() + 1));
    if (!buf) return 2;

    std::memcpy(buf, getLastErrorData(), getLastErrorSize());
    buf[getLastErrorSize()] = '\0';

    *reason_ptr = buf;
    *reason_len = getLastErrorSize();
    return 0;
}

int tintSPIRVReaderReadIR(const uint32_t* spirv, size_t word_count, void** ir_module) {
    if (!spirv || !ir_module) {
        setLastError("invalid argument");
        return 1;
    }
    clearLastError();

    std::vector<uint32_t> bin(spirv, spirv + word_count);
    tint::Result<tint::core::ir::Module> result = tint::spirv::reader::ReadIR(bin, {});
    if (result != tint::Success) {
        setLastError(result.Failure().reason);
        return 2;
    }

    *ir_module = new tint::core::ir::Module(std::move(result.Get()));
    return 0;
}

void tintFreeIR(void** ir_module) {
    if (!ir_module || !*ir_module) return;
    delete static_cast<tint::core::ir::Module*>(*ir_module);
}

int tintWGSLWriterFromIR(void** ir_module, char** out_wgsl, size_t* out_len) {
    if (!ir_module || !*ir_module || !out_wgsl || !out_len) {
        setLastError("invalid argument");
        return 1;
    }
    clearLastError();

    tint::core::ir::Module* module = static_cast<tint::core::ir::Module*>(*ir_module);
    tint::Result<tint::wgsl::writer::Output> result = tint::wgsl::writer::WgslFromIR(*module, {});
    if (result != tint::Success) {
        setLastError(result.Failure().reason);
        return 2;
    }

    char* buf = static_cast<char*>(std::malloc(result->wgsl.size() + 1));
    if (!buf) {
        setLastError("out of memory");
        return 3;
    }

    std::memcpy(buf, result->wgsl.data(), result->wgsl.size());
    buf[result->wgsl.size()] = '\0';

    *out_wgsl = buf;
    *out_len = result->wgsl.size();
    return 0;
}

#ifdef __cplusplus
} // extern "C"
#endif
