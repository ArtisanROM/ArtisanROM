# ARM32 system compatibility layer for legacy Exynos 990 services.
# The zzz_ module order is intentional: install and validate the compatibility
# runtime after the platform donor modules have populated the work directory.
#
# The Android 16 S926B source image is 64-bit-only and therefore has no
# /system/bin/linker or 32-bit system library namespace.  The M35x runtime
# APEX is also Android 16, but contains both Bionic architectures.  Keep this
# module platform-wide and do not change zygote/abilist properties: the goal is
# to expose the 32-bit runtime entry points required by OMX and remaining legacy
# vendor services. The non-Bionic ARM32 system libraries are
# supplied by the Android 16 r11s donor; vendor/SoC-specific HAL libraries
# remain untouched.

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -lt 36 ]]; then
    LOG "- Source is not Android 16; skipping Exynos 990 32-bit runtime compatibility"
    return 0
fi

LOG_STEP_IN "- Adding Android 16 ARM32 runtime compatibility for Exynos 990"

RUNTIME_APEX="system/apex/com.android.runtime.apex"
RUNTIME_APEX_PATH="$WORK_DIR/system/system/apex/com.android.runtime.apex"
I18N_APEX="system/apex/com.android.i18n.apex"
I18N_APEX_PATH="$WORK_DIR/system/system/apex/com.android.i18n.apex"
ART_APEX="system/apex/com.google.android.art_compressed.apex"
ART_APEX_PATH="$WORK_DIR/system/system/apex/com.google.android.art_compressed.apex"

ADD_TO_WORK_DIR "m35xxx" "system" "$RUNTIME_APEX" \
    0 0 644 "u:object_r:system_file:s0" || return 1
ADD_TO_WORK_DIR "r11sxxx" "system" "$I18N_APEX" \
    0 0 644 "u:object_r:system_file:s0" || return 1
ADD_TO_WORK_DIR "r11sxxx" "system" "$ART_APEX" \
    0 0 644 "u:object_r:system_file:s0" || return 1

if [ ! -f "$RUNTIME_APEX_PATH" ]; then
    ABORT "M35x runtime APEX was not added"
    return 1
fi
if [ ! -f "$I18N_APEX_PATH" ]; then
    ABORT "R11s multilib I18n APEX was not added"
    return 1
fi
if [ ! -f "$ART_APEX_PATH" ]; then
    ABORT "R11s multilib ART APEX was not added"
    return 1
fi

# These are the system-side ARM32 libraries that are absent from the S926B
# 64-bit-only source but are required by the target's existing 32-bit vendor
# executables and the legacy audio HAL shared-object graph.  Use r11s for all
# loose libraries; m35x is retained only as the multilib Runtime APEX donor.
# No SoC-specific vendor library is copied here.
RUNTIME_LIBS="
android.hardware.common-V2-ndk.so
android.hardware.configstore-utils.so
android.hardware.configstore@1.0.so
android.hardware.configstore@1.1.so
android.hardware.graphics.allocator-V2-ndk.so
android.hardware.graphics.allocator@2.0.so
android.hardware.graphics.allocator@3.0.so
android.hardware.graphics.allocator@4.0.so
android.hardware.graphics.common-V7-ndk.so
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
libclang_rt.ubsan_standalone-arm-android.so
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
    ADD_TO_WORK_DIR "r11sxxx" "system" "system/lib/$RUNTIME_LIB" \
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
# Exynos 990 audio path is a 32-bit HIDL 5.0 service.  Only generic
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

# Import only the missing system-side dependencies required by the legacy OMX
# and vendor-service roots. Resolve their DT_NEEDED closure from the Android 16
# r11s donor instead of carrying unrelated feature-specific library graphs.
declare -A R11S_VISITED=()
R11S_IMPORTED_COUNT=0

ADD_R11S_SYSTEM_LIB()
{
    local LIB_NAME="$1"
    local DONOR_LIB="$SRC_DIR/prebuilts/samsung/r11sxxx/system/lib/$LIB_NAME"
    local NEEDED_LIB

    [ "$LIB_NAME" ] || return 0
    [ "${R11S_VISITED[$LIB_NAME]+set}" ] && return 0
    R11S_VISITED["$LIB_NAME"]=1

    # Bionic and ICU are supplied by the multilib Runtime/I18n APEXes.
    case "$LIB_NAME" in
        libc.so|libdl.so|libdl_android.so|libm.so|libandroidicu.so)
            return 0
            ;;
    esac

    [ -e "$WORK_DIR/system/system/lib/$LIB_NAME" ] && return 0
    if [ ! -f "$DONOR_LIB" ]; then
        ABORT "Missing r11s ARM32 dependency: system/lib/$LIB_NAME"
        return 1
    fi

    ADD_TO_WORK_DIR "r11sxxx" "system" "system/lib/$LIB_NAME" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
    ((R11S_IMPORTED_COUNT += 1))

    while read -r NEEDED_LIB; do
        ADD_R11S_SYSTEM_LIB "$NEEDED_LIB" || return 1
    done < <(readelf -d "$DONOR_LIB" 2>/dev/null | \
        sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
}

LOG "- Adding required r11s Android 16 ARM32 system libraries"
ADD_R11S_SYSTEM_LIB "libmediandk.so" || return 1
ADD_R11S_SYSTEM_LIB "libselinux.so" || return 1
LOG "  - Imported $R11S_IMPORTED_COUNT libraries from the r11s dependency closure"

OMX_SERVICE="$WORK_DIR/vendor/bin/hw/android.hardware.media.omx@1.0-service"
if [ ! -f "$OMX_SERVICE" ]; then
    ABORT "Legacy OMX service is missing from the target vendor"
    return 1
fi

if ! readelf -h "$OMX_SERVICE" 2>/dev/null | grep "ELF32" >/dev/null; then
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

unset RUNTIME_APEX RUNTIME_APEX_PATH I18N_APEX I18N_APEX_PATH \
    ART_APEX ART_APEX_PATH \
    RUNTIME_LIBS RUNTIME_LIB LEGACY_AUDIO_LIBS \
    LEGACY_AUDIO_LIB OMX_SERVICE \
    R11S_VISITED R11S_IMPORTED_COUNT \
    RUNTIME_LINKS RUNTIME_RELATIVE RUNTIME_TARGET RUNTIME_USER RUNTIME_GROUP \
    RUNTIME_MODE RUNTIME_LABEL
unset -f ADD_R11S_SYSTEM_LIB ADD_RUNTIME_LINK

LOG "  - Multilib Runtime/I18n/ART APEXes and r11s ARM32 libraries added for legacy services"
LOG_STEP_OUT
