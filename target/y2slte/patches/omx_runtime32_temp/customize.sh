# Experimental compatibility layer for the legacy Exynos 990 OMX service.
#
# The Android 16 S926B source image is 64-bit-only and therefore has no
# /system/bin/linker or 32-bit system library namespace.  The M35x runtime
# APEX is also Android 16, but contains both Bionic architectures.  Keep this
# module target-local and do not change zygote/abilist properties: the goal is
# only to expose the 32-bit runtime entry points.  Vendor/SoC-specific HAL
# libraries remain untouched; only the Android 16 system-side ARM32 closure
# required by the existing 32-bit vendor executables is imported.

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    LOG "- Source is not Android 16; skipping temporary 32-bit runtime"
    return 0
fi

LOG_STEP_IN "- Adding M35x Android 16 runtime for legacy OMX"

RUNTIME_APEX="system/apex/com.android.runtime.apex"
RUNTIME_APEX_PATH="$WORK_DIR/system/system/apex/com.android.runtime.apex"

ADD_TO_WORK_DIR "m35xxx" "system" "$RUNTIME_APEX" \
    0 0 644 "u:object_r:system_file:s0" || return 1

if [ ! -f "$RUNTIME_APEX_PATH" ]; then
    ABORT "M35x runtime APEX was not added"
    return 1
fi

# These are the system-side ARM32 libraries that are absent from the S926B
# 64-bit-only source but are required by the target's existing 32-bit vendor
# executables and the legacy audio HAL shared-object graph; no SoC-specific
# vendor library is copied here.  The closure is kept explicit so a future
# donor update cannot silently pull in unrelated files.
RUNTIME_LIBS="
android.hardware.common-V2-ndk.so
android.hardware.configstore-utils.so
android.hardware.configstore@1.0.so
android.hardware.configstore@1.1.so
android.hardware.graphics.allocator-V2-ndk.so
android.hardware.graphics.allocator@2.0.so
android.hardware.graphics.allocator@3.0.so
android.hardware.graphics.allocator@4.0.so
android.hardware.graphics.common-V6-ndk.so
android.hardware.graphics.common@1.0.so
android.hardware.graphics.common@1.1.so
android.hardware.graphics.common@1.2.so
android.hardware.graphics.mapper@2.0.so
android.hardware.graphics.mapper@2.1.so
android.hardware.graphics.mapper@3.0.so
android.hardware.graphics.mapper@4.0.so
android.hidl.allocator@1.0.so
android.hidl.memory@1.0.so
android.hidl.memory.token@1.0.so
android.hidl.safe_union@1.0.so
android.system.suspend-V1-ndk.so
libaconfig_storage_read_api_cc.so
libEGL.so
libegl_flags.so
libexpat.so
libGLESv2.so
libGLESv3.so
libSurfaceFlingerProp.so
libapexsupport.so
libaudioutils.so
libbase.so
libbinder.so
libc++.so
libbinder_ndk.so
libcgrouprc.so
libcutils.so
libgralloctypes.so
libgraphicsenv.so
libhidlbase.so
libhidlmemory.so
libhwbinder.so
liblog.so
liblzma.so
libnativebridge_lazy.so
libnativeloader_lazy.so
libnativewindow.so
libprocessgroup.so
libprocinfo.so
libfmq.so
libhardware.so
libhardware_legacy.so
libmedia_helper.so
libspeexresampler.so
libsync.so
libtinyalsa.so
libtinyxml2.so
libui.so
libunwindstack.so
libutils.so
libutilscallstack.so
libvndksupport.so
libz.so
server_configurable_flags.so
"

while read -r RUNTIME_LIB; do
    [ "$RUNTIME_LIB" ] || continue
    ADD_TO_WORK_DIR "m35xxx" "system" "system/lib/$RUNTIME_LIB" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
done <<< "$RUNTIME_LIBS"

# gralloc.exynos990.so is a legacy 32-bit target module and links against
# GLESv1 directly.  The S926B source is 64-bit-only, while the generic M35x
# runtime set above does not ship this compatibility library.  Keep the
# target implementation (it matches the Exynos 990 gralloc ABI); its Android
# EGL entry point is provided by the imported 32-bit libEGL.so.
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
    "system/lib/libGLESv1_CM.so" 0 0 644 \
    "u:object_r:system_lib_file:s0" || return 1

# Do not import the M35x vendor audio HAL here: its service is 64-bit and its
# implementation is bound to the Exynos 1380 (s5e8835) primary driver.  The
# y2slte audio path is a 32-bit Exynos 990 HIDL 5.0 service.  Only generic
# system-side ABI libraries are safe to share between those devices.
#
# The target's legacy 32-bit audio HAL is HIDL 5.0.  Its interface libraries
# are not part of the Android 16 source image (which only ships newer 64-bit
# audio interfaces), so retain the matching 32-bit target-side HIDL ABI glue.
# These are generic framework interfaces, not Exynos-specific drivers.
LEGACY_AUDIO_LIBS="
android.hardware.audio.common@5.0.so
android.hardware.audio.common@5.0-util.so
android.hardware.audio.effect@5.0.so
android.hardware.audio.effect@5.0-util.so
android.hardware.audio@5.0.so
android.hardware.audio@5.0-util.so
"
while read -r LEGACY_AUDIO_LIB; do
    [ "$LEGACY_AUDIO_LIB" ] || continue
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/$LEGACY_AUDIO_LIB" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
done <<< "$LEGACY_AUDIO_LIBS"

OMX_SERVICE="$WORK_DIR/vendor/bin/hw/android.hardware.media.omx@1.0-service"
if [ ! -f "$OMX_SERVICE" ]; then
    ABORT "Legacy OMX service is missing from the target vendor"
    return 1
fi

if ! readelf -h "$OMX_SERVICE" 2>/dev/null | grep -q "ELF32"; then
    ABORT "Target OMX service is not a 32-bit ELF"
    return 1
fi

# Recreate the standard runtime links present on a multilib Android image.
# The S926B source has only the linker64 variants.  Do not overwrite a real
# file: a stale/non-standard file is safer to reject than to silently replace.
ADD_RUNTIME_LINK()
{
    local RELATIVE="$1"
    local TARGET="$2"
    local USER="$3"
    local GROUP="$4"
    local MODE="$5"
    local LABEL="$6"
    # The system partition is rooted at $WORK_DIR/system, and its actual
    # system root is the nested $WORK_DIR/system/system directory.
    local LINK="$WORK_DIR/system/$RELATIVE"
    local FC_RELATIVE="${RELATIVE//./\\.}"
    FC_RELATIVE="${FC_RELATIVE//+/\\+}"

    if [ -e "$LINK" ] && [ ! -L "$LINK" ]; then
        ABORT "Refusing to replace regular file: $RELATIVE"
        return 1
    fi

    mkdir -p "$(dirname "$LINK")" || return 1
    ln -sfn "$TARGET" "$LINK" || return 1

    if ! grep -q -F "$RELATIVE " "$WORK_DIR/configs/fs_config-system" 2>/dev/null; then
        printf '%s %s %s %s capabilities=0x0\n' \
            "$RELATIVE" "$USER" "$GROUP" "$MODE" \
            >> "$WORK_DIR/configs/fs_config-system"
    fi
    if ! grep -q -F "/$FC_RELATIVE " "$WORK_DIR/configs/file_context-system" 2>/dev/null; then
        printf '/%s %s\n' "$FC_RELATIVE" "$LABEL" \
            >> "$WORK_DIR/configs/file_context-system"
    fi
}

RUNTIME_LINKS="
system/bin/linker|/apex/com.android.runtime/bin/linker|0|2000|755|u:object_r:system_linker_exec:s0
system/bin/linker_asan|/apex/com.android.runtime/bin/linker|0|2000|755|u:object_r:system_file:s0
system/bin/linkerconfig|/apex/com.android.runtime/bin/linkerconfig|0|2000|755|u:object_r:linkerconfig_exec:s0
system/lib/libc.so|/apex/com.android.runtime/lib/bionic/libc.so|0|0|644|u:object_r:system_lib_file:s0
system/lib/libdl.so|/apex/com.android.runtime/lib/bionic/libdl.so|0|0|644|u:object_r:system_lib_file:s0
system/lib/libdl_android.so|/apex/com.android.runtime/lib/bionic/libdl_android.so|0|0|644|u:object_r:system_lib_file:s0
system/lib/libm.so|/apex/com.android.runtime/lib/bionic/libm.so|0|0|644|u:object_r:system_lib_file:s0
"

while IFS='|' read -r RUNTIME_RELATIVE RUNTIME_TARGET RUNTIME_USER \
        RUNTIME_GROUP RUNTIME_MODE RUNTIME_LABEL; do
    [ "$RUNTIME_RELATIVE" ] || continue
    ADD_RUNTIME_LINK "$RUNTIME_RELATIVE" "$RUNTIME_TARGET" \
        "$RUNTIME_USER" "$RUNTIME_GROUP" "$RUNTIME_MODE" "$RUNTIME_LABEL" || \
        return 1
done <<< "$RUNTIME_LINKS"

unset RUNTIME_APEX RUNTIME_APEX_PATH RUNTIME_LIBS RUNTIME_LIB LEGACY_AUDIO_LIBS \
    LEGACY_AUDIO_LIB OMX_SERVICE \
    RUNTIME_LINKS RUNTIME_RELATIVE RUNTIME_TARGET RUNTIME_USER RUNTIME_GROUP \
    RUNTIME_MODE RUNTIME_LABEL
unset -f ADD_RUNTIME_LINK

LOG "  - M35x runtime APEX and 32-bit linker links added (no vendor libraries imported)"
LOG_STEP_OUT
