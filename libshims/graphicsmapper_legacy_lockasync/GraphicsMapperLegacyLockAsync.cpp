/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <atomic>
#include <dlfcn.h>

#include <android/log.h>
#include <grallocusage/GrallocUsageConversion.h>
#include <ui/GraphicBufferMapper.h>

__attribute__((constructor)) static void logShimLoadAndResolution() {
    static constexpr char kSymbol[] =
            "_ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handleyyRKNS_4RectEPPviPiS9_";
    static constexpr char kLegacyLockSymbol[] =
            "_ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPv";
    void* resolved = dlsym(RTLD_DEFAULT, kSymbol);
    void* exynos = dlopen("libexynosgraphicbuffer.so", RTLD_NOW | RTLD_NOLOAD);
    void* exynosResolved = exynos ? dlsym(exynos, kSymbol) : nullptr;
    void* encoder = dlopen("libOMX.Exynos.AVC.Encoder.so", RTLD_NOW | RTLD_NOLOAD);
    void* encoderResolved = encoder ? dlsym(encoder, kLegacyLockSymbol) : nullptr;
    Dl_info info{};
    const char* resolvedFrom = dladdr(resolved, &info) ? info.dli_fname : "unknown";
    Dl_info exynosInfo{};
    const char* exynosResolvedFrom =
            dladdr(exynosResolved, &exynosInfo) ? exynosInfo.dli_fname : "unknown";
    Dl_info encoderInfo{};
    const char* encoderResolvedFrom =
            dladdr(encoderResolved, &encoderInfo) ? encoderInfo.dli_fname : "unknown";
    __android_log_print(ANDROID_LOG_ERROR, "libshim_graphicsmapper",
                        "shim loaded; async=%p from=%s exynos=%p/%p from=%s encoder=%p/%p from=%s",
                        resolved, resolvedFrom, exynos, exynosResolved, exynosResolvedFrom,
                        encoder, encoderResolved, encoderResolvedFrom);
    if (exynos) dlclose(exynos);
    if (encoder) dlclose(encoder);
}

static void resolveLegacyByteLayoutFromPlaneLayout(
        const std::vector<android::ui::PlaneLayout>& planeLayouts, int32_t* outBytesPerPixel,
        int32_t* outBytesPerStride) {
    if (planeLayouts.empty()) return;

    if (outBytesPerPixel) {
        int32_t bitsPerPixel = planeLayouts.front().sampleIncrementInBits;
        for (const auto& planeLayout : planeLayouts) {
            if (bitsPerPixel != planeLayout.sampleIncrementInBits) {
                bitsPerPixel = -1;
                break;
            }
        }
        *outBytesPerPixel = bitsPerPixel >= 0 && bitsPerPixel % 8 == 0 ? bitsPerPixel / 8 : -1;
    }

    if (outBytesPerStride) {
        int32_t bytesPerStride = planeLayouts.front().strideInBytes;
        for (const auto& planeLayout : planeLayouts) {
            if (bytesPerStride != planeLayout.strideInBytes) {
                bytesPerStride = -1;
                break;
            }
        }
        *outBytesPerStride = bytesPerStride;
    }
}

extern "C" android::status_t
_ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handlemmRKNS_4RectEPPviPiS9_(
        android::GraphicBufferMapper* mapper, buffer_handle_t handle, uint64_t producerUsage,
        uint64_t consumerUsage, const android::Rect& bounds, void** vaddr, int fenceFd,
        int* outBytesPerPixel, int* outBytesPerStride) {
    static std::atomic<unsigned int> loggedCalls{0};
    const unsigned int call = loggedCalls.fetch_add(1, std::memory_order_relaxed);
    const int mapperVersion = mapper->getMapperVersion();
    int32_t legacyBytesPerPixel = -1;
    int32_t legacyBytesPerStride = -1;

    if (call < 16) {
        __android_log_print(ANDROID_LOG_INFO, "libshim_graphicsmapper",
                            "legacy lock enter call=%u ABI=%zu mapper=%d handle=%p usage=%llx/%llx rect=%d,%d,%d,%d fence=%d out=%p/%p",
                            call, sizeof(void*) * 8, mapperVersion, handle,
                            static_cast<unsigned long long>(producerUsage),
                            static_cast<unsigned long long>(consumerUsage), bounds.left,
                            bounds.top, bounds.right, bounds.bottom, fenceFd, outBytesPerPixel,
                            outBytesPerStride);
    }

    if (outBytesPerPixel || outBytesPerStride) {
        if (mapperVersion >= android::GraphicBufferMapper::GRALLOC_4) {
            auto planeLayouts = mapper->getPlaneLayouts(handle);
            if (!planeLayouts.has_value()) {
                const android::status_t status = planeLayouts.asStatus();
                if (call < 16) {
                    __android_log_print(ANDROID_LOG_ERROR, "libshim_graphicsmapper",
                                        "legacy lock call=%u getPlaneLayouts failed status=%d",
                                        call, status);
                }
                return status;
            }
            if (call < 16) {
                __android_log_print(ANDROID_LOG_INFO, "libshim_graphicsmapper",
                                    "legacy lock call=%u got %zu plane layouts", call,
                                    planeLayouts.value().size());
            }
            resolveLegacyByteLayoutFromPlaneLayout(planeLayouts.value(), &legacyBytesPerPixel,
                                                   &legacyBytesPerStride);
        }
    }

    const int64_t usage = static_cast<int64_t>(static_cast<uint32_t>(
            android_convertGralloc1To0Usage(producerUsage, consumerUsage)));
    auto lockResult = mapper->lock(handle, usage, bounds, android::base::unique_fd{fenceFd});
    if (!lockResult.has_value()) {
        const android::status_t status = lockResult.asStatus();
        if (call < 16) {
            __android_log_print(ANDROID_LOG_ERROR, "libshim_graphicsmapper",
                                "legacy lock call=%u mapper.lock failed status=%d usage=%llx",
                                call, status, static_cast<unsigned long long>(usage));
        }
        return status;
    }

    const auto& value = lockResult.value();
    *vaddr = value.address;
    if (outBytesPerPixel) {
        *outBytesPerPixel = legacyBytesPerPixel != -1 ? legacyBytesPerPixel : value.bytesPerPixel;
    }
    if (outBytesPerStride) {
        *outBytesPerStride =
                legacyBytesPerStride != -1 ? legacyBytesPerStride : value.bytesPerStride;
    }

    if (call < 16) {
        __android_log_print(ANDROID_LOG_INFO, "libshim_graphicsmapper",
                            "legacy lock call=%u succeeded bpp=%d bps=%d", call,
                            outBytesPerPixel ? *outBytesPerPixel : -1,
                            outBytesPerStride ? *outBytesPerStride : -1);
    }
    return android::OK;
}

extern "C" android::status_t
_ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handleyyRKNS_4RectEPPviPiS9_(
        android::GraphicBufferMapper* mapper, buffer_handle_t handle, uint64_t producerUsage,
        uint64_t consumerUsage, const android::Rect& bounds, void** vaddr, int fenceFd,
        int* outBytesPerPixel, int* outBytesPerStride) {
    return _ZN7android19GraphicBufferMapper9lockAsyncEPK13native_handlemmRKNS_4RectEPPviPiS9_(
            mapper, handle, producerUsage, consumerUsage, bounds, vaddr, fenceFd,
            outBytesPerPixel, outBytesPerStride);
}
