/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <dlfcn.h>

#include <android/log.h>
#include <ui/GraphicBufferMapper.h>

using LegacyLockAsyncFn = android::status_t (*)(android::GraphicBufferMapper*, buffer_handle_t,
                                                uint64_t, uint64_t, const android::Rect&, void**,
                                                int);

extern "C" android::status_t
_ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handlemmRKNS_4RectEPPviPiS9_(
        android::GraphicBufferMapper* mapper, buffer_handle_t handle, uint64_t producerUsage,
        uint64_t consumerUsage, const android::Rect& bounds, void** vaddr, int fenceFd,
        int* outBytesPerPixel, int* outBytesPerStride) {
    if (outBytesPerPixel) {
        *outBytesPerPixel = 0;
    }
    if (outBytesPerStride) {
        *outBytesPerStride = 0;
    }

    static auto realLockAsync = reinterpret_cast<LegacyLockAsyncFn>(dlsym(
            RTLD_NEXT,
            "_ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handlemmRKNS_4RectEPPvi"));

    if (!realLockAsync) {
        __android_log_print(ANDROID_LOG_ERROR, "libshim_graphicsmapper",
                            "failed to resolve current GraphicBufferMapper::lockAsync");
        return android::UNKNOWN_ERROR;
    }

    return realLockAsync(mapper, handle, producerUsage, consumerUsage, bounds, vaddr, fenceFd);
}
