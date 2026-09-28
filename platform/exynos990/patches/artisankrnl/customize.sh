# [
EXTREMEKRNL_REPO="https://github.com/Android-Artisan/android_kernel_samsung_exynos990"

KERNEL_MODEL="$TARGET_CODENAME"
KERNEL_CACHE_VERSION="2"
KERNEL_PATCH_DIR="$MODPATH/patches"

GET_FILE_SHA256()
{
    sha256sum "$1" | cut -d " " -f 1
}

GET_KERNEL_PATCHSET_DIGEST()
{
    local PATCH
    local PATCHES=("$KERNEL_PATCH_DIR"/*.patch)

    if [ ! -e "${PATCHES[0]}" ]; then
        printf 'none\n'
        return 0
    fi
    for PATCH in "${PATCHES[@]}"; do
        printf '%s  %s\n' "$(GET_FILE_SHA256 "$PATCH")" "$(basename "$PATCH")"
    done | sha256sum | cut -d " " -f 1
}

GET_KERNEL_CACHE_KEY()
{
    # Include every input owned by this integration. In particular, the old
    # key omitted the external patch set, so changing a patch could still
    # select an image produced before that change.
    {
        printf 'cache-version=%s\n' "$KERNEL_CACHE_VERSION"
        git -C "$KERNEL_TMP_DIR" rev-parse HEAD
        git -C "$KERNEL_TMP_DIR" diff --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" diff --cached --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" submodule status --recursive
        printf 'patchset=%s\n' "$(GET_KERNEL_PATCHSET_DIGEST)"
        printf 'integration=%s\n' "$(GET_FILE_SHA256 "$MODPATH/customize.sh")"
        printf 'main: model=%s ksu=y recovery=n\n' "$KERNEL_MODEL"
        if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
            printf 'main: model=%s ksu=n recovery=n dt_overlay=y\n' "${TARGET_CODENAME}lte"
        fi
    } | sha256sum | cut -d " " -f 1
}

GET_CACHE_VALUE()
{
    local CACHE_FILE="$1"
    local KEY="$2"

    sed -n "s/^${KEY}=//p" "$CACHE_FILE" | head -n 1
}

GET_BOOT_KERNEL_SHA256()
{
    local BOOT_IMAGE="$1"
    local KERNEL_SIZE
    local MAGIC
    local PAGE_SIZE

    MAGIC="$(dd if="$BOOT_IMAGE" bs=8 count=1 status=none 2>/dev/null)"
    [ "$MAGIC" = "ANDROID!" ] || return 1

    KERNEL_SIZE="$(od -An -tu4 -j8 -N4 "$BOOT_IMAGE" | tr -d ' ')"
    PAGE_SIZE="$(od -An -tu4 -j36 -N4 "$BOOT_IMAGE" | tr -d ' ')"
    [[ "$KERNEL_SIZE" =~ ^[0-9]+$ ]] || return 1
    [[ "$PAGE_SIZE" =~ ^[0-9]+$ ]] || return 1
    [ "$KERNEL_SIZE" -gt 0 ] || return 1
    [ "$PAGE_SIZE" -gt 0 ] || return 1

    dd if="$BOOT_IMAGE" bs=1M iflag=skip_bytes,count_bytes \
        skip="$PAGE_SIZE" count="$KERNEL_SIZE" status=none 2>/dev/null |
        sha256sum | cut -d " " -f 1
}

VERIFY_BUILT_KERNEL_ARTIFACTS()
{
    local IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/Image"
    local VMLINUX="$KERNEL_TMP_DIR/out/vmlinux"

    [ -s "$IMAGE" ] || ABORT "Kernel build did not produce a non-empty Image."
    [ -s "$VMLINUX" ] || ABORT "Kernel build did not produce a non-empty vmlinux."
    cmp -s "$IMAGE" "$KERNEL_TMP_DIR/out/arch/arm64/boot/Image" ||
        ABORT "Packaged kernel Image does not match the Image from the current build tree."

    LOG "- Verified that the packaged Image belongs to the current kernel build tree."
}

CLEAN_KERNEL_BUILD_OUTPUTS()
{
    local KBUILD_OUT="$KERNEL_TMP_DIR/out"
    local MODEL_OUT="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL"
    local LTE_MODEL_OUT="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte"

    # These paths are deliberately constrained to the cloned kernel tree.
    # Never let an unset or malformed path turn this into a broad deletion.
    case "$KBUILD_OUT" in
        "$OUT_DIR"/kernel_tmp-*/out) ;;
        *) ABORT "Refusing to clean unexpected kernel output path: $KBUILD_OUT" ;;
    esac
    case "$MODEL_OUT" in
        "$OUT_DIR"/kernel_tmp-*/build/out/*) ;;
        *) ABORT "Refusing to clean unexpected packaged-kernel path: $MODEL_OUT" ;;
    esac

    LOG "- Removing stale Kbuild and packaged-kernel outputs."
    rm -rf -- "$KBUILD_OUT" "$MODEL_OUT"
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        rm -rf -- "$LTE_MODEL_OUT"
    fi
    rm -f -- "$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"
}

KERNEL_CACHE_IS_VALID()
{
    local CACHE_FILE="$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"
    local BOOT_IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img"
    local DTBO_IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img"
    local IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/Image"
    local LTE_DTBO_IMAGE="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img"

    [ -f "$CACHE_FILE" ] || return 1
    [ "$(GET_CACHE_VALUE "$CACHE_FILE" version)" = "$KERNEL_CACHE_VERSION" ] || return 1
    [ "$(GET_CACHE_VALUE "$CACHE_FILE" key)" = "$KERNEL_CACHE_KEY" ] || return 1
    [ -s "$IMAGE" ] || return 1
    [ -s "$BOOT_IMAGE" ] || return 1
    [ -s "$DTBO_IMAGE" ] || return 1
    [ "$(GET_FILE_SHA256 "$IMAGE")" = "$(GET_CACHE_VALUE "$CACHE_FILE" image_sha256)" ] || return 1
    [ "$(GET_FILE_SHA256 "$BOOT_IMAGE")" = "$(GET_CACHE_VALUE "$CACHE_FILE" boot_sha256)" ] || return 1
    [ "$(GET_FILE_SHA256 "$DTBO_IMAGE")" = "$(GET_CACHE_VALUE "$CACHE_FILE" dtbo_sha256)" ] || return 1
    [ "$(GET_BOOT_KERNEL_SHA256 "$BOOT_IMAGE")" = "$(GET_FILE_SHA256 "$IMAGE")" ] || return 1

    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        [ -s "$LTE_DTBO_IMAGE" ] || return 1
        [ "$(GET_FILE_SHA256 "$LTE_DTBO_IMAGE")" = "$(GET_CACHE_VALUE "$CACHE_FILE" lte_dtbo_sha256)" ] || return 1
    fi

    VERIFY_BUILT_KERNEL_ARTIFACTS
    return 0
}

BUILD_KERNEL()
{
    local BOOT_IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img"
    local BUILD_MARKER="$KERNEL_TMP_DIR/.unica-kernel-build-start-${TARGET_CODENAME}"
    local DTBO_IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img"
    local IMAGE="$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/Image"
    local ARTIFACT
    local PARENT
    PARENT="$(pwd)"

    CLEAN_KERNEL_BUILD_OUTPUTS
    touch "$BUILD_MARKER" || return 1
    cd "$KERNEL_TMP_DIR" || return 1

    # Kernel builds are long-running and their output is needed to diagnose
    # compiler failures. Do not hide it inside EVAL's command substitution.
    LOG "- Building kernel for ${TARGET_CODENAME}"
    if ! EVAL "./build.sh -m "$KERNEL_MODEL" -k y -r n"; then
        cd "$PARENT" || return 1
        rm -f -- "$BUILD_MARKER"
        return 1
    fi

    # Existence alone is insufficient: a failed build used to leave an older
    # boot.img in this directory, which was then accepted and cached.
    for ARTIFACT in "$IMAGE" "$BOOT_IMAGE" "$DTBO_IMAGE"; do
        if [ ! -s "$ARTIFACT" ] || [ ! "$ARTIFACT" -nt "$BUILD_MARKER" ]; then
            cd "$PARENT" || return 1
            rm -f -- "$BUILD_MARKER"
            LOGE "Kernel build did not freshly generate ${ARTIFACT//$KERNEL_TMP_DIR\//}."
            return 1
        fi
    done

    if [ "$(GET_BOOT_KERNEL_SHA256 "$BOOT_IMAGE")" != "$(GET_FILE_SHA256 "$IMAGE")" ]; then
        cd "$PARENT" || return 1
        rm -f -- "$BUILD_MARKER"
        LOGE "boot.img does not contain the Image generated by this build."
        return 1
    fi
    VERIFY_BUILT_KERNEL_ARTIFACTS

    # Fixup for LTE devices: build LTE variant without KernelSU, with DT overlay
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        LOG "- Building kernel for ${TARGET_CODENAME}lte (DT overlay)"
        if ! EVAL "./build.sh -m "${TARGET_CODENAME}lte" -k n -r n -d y"; then
            cd "$PARENT" || return 1
            rm -f -- "$BUILD_MARKER"
            return 1
        fi
        if [ ! -s "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" ] ||
                [ ! "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" -nt "$BUILD_MARKER" ]; then
            cd "$PARENT" || return 1
            rm -f -- "$BUILD_MARKER"
            LOGE "Kernel build did not freshly generate the LTE dtbo.img."
            return 1
        fi
    fi

    cd "$PARENT" || return 1
    rm -f -- "$BUILD_MARKER"
    return 0
}

INIT_KERNEL_SUBMODULES()
{
    # The kernel repository pins the tested KernelSU-Next legacy revision.
    # Sync first so URL/branch changes from a kernel update are respected.
    EVAL "git -C \"$KERNEL_TMP_DIR\" submodule sync --recursive"
    EVAL "git -C \"$KERNEL_TMP_DIR\" submodule update --init --recursive"
}

APPLY_KERNEL_PATCHES()
{
    local PATCH
    local PATCHES=("$KERNEL_PATCH_DIR"/*.patch)

    if [ ! -e "${PATCHES[0]}" ]; then
        LOG "- No external kernel compatibility patches for this branch."
        return 0
    fi

    for PATCH in "${PATCHES[@]}"; do
        if git -C "$KERNEL_TMP_DIR" apply --check "$PATCH" > /dev/null 2>&1; then
            LOG "- Applying kernel compatibility patch: $(basename "$PATCH")"
            EVAL "git -C \"$KERNEL_TMP_DIR\" apply \"$PATCH\""
        elif git -C "$KERNEL_TMP_DIR" apply --reverse --check "$PATCH" > /dev/null 2>&1; then
            LOG "- Kernel compatibility patch already applied: $(basename "$PATCH")"
        else
            ABORT "Could not apply kernel compatibility patch $(basename "$PATCH") to the ExtremeKRNL source."
            return 1
        fi
    done
}

WRITE_KERNEL_CACHE_MANIFEST()
{
    local CACHE_FILE="$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"
    local LTE_DTBO="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img"
    local TEMP_FILE="${CACHE_FILE}.tmp"

    {
        printf 'version=%s\n' "$KERNEL_CACHE_VERSION"
        printf 'key=%s\n' "$KERNEL_CACHE_KEY"
        printf 'commit=%s\n' "$(git -C "$KERNEL_TMP_DIR" rev-parse HEAD)"
        printf 'patchset=%s\n' "$(GET_KERNEL_PATCHSET_DIGEST)"
        printf 'image_sha256=%s\n' \
            "$(GET_FILE_SHA256 "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/Image")"
        printf 'boot_sha256=%s\n' \
            "$(GET_FILE_SHA256 "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img")"
        printf 'dtbo_sha256=%s\n' \
            "$(GET_FILE_SHA256 "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img")"
        if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
            printf 'lte_dtbo_sha256=%s\n' "$(GET_FILE_SHA256 "$LTE_DTBO")"
        fi
    } > "$TEMP_FILE" || return 1

    mv -f -- "$TEMP_FILE" "$CACHE_FILE"
}

SAFE_PULL_CHANGES()
(
    # Keep errexit/pipefail local to this subshell. Leaking errexit caused a
    # later failed kernel command to terminate before EVAL could print it.
    set -eo pipefail

    local PARENT
    PARENT="$(pwd)"

    cd "$KERNEL_TMP_DIR" || return 1

    EVAL "git fetch origin"

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/bpf111)
    BASE=$(git merge-base @ origin/bpf111)

    # Now we have three cases that we need to take care of.
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        LOG "- Local branch is up-to-date with remote."
    elif [[ "$LOCAL" == "$BASE" ]]; then
        LOG "- Fast-forward possible. Pulling."
        EVAL "git pull --ff-only"
    elif [[ "$REMOTE" == "$BASE" ]]; then
        LOGW "- Local branch is ahead of remote. Not doing anything."
    else
        cd "$PARENT" || return 1
        ABORT "Remote history has diverged (possible force-push)."
    fi

    cd "$PARENT" || return 1
)

REPLACE_KERNEL_BINARIES()
{
    local KERNEL_TMP_DIR="$OUT_DIR/kernel_tmp-$TARGET_PLATFORM"
    local KERNEL_CACHE_KEY
    local KERNEL_COMMIT
    [[ ! -d "$KERNEL_TMP_DIR" ]] && mkdir -p "$KERNEL_TMP_DIR"

    if [[ -d "$KERNEL_TMP_DIR/.git" ]]; then
        LOG "- Existing git repo found, trying to pull latest changes"
        if ! SAFE_PULL_CHANGES; then
            ABORT "Could not pull latest Kernel changes. If you hold local changes, please rebase to the new base. If not, cleaning the kernel_tmp_dir should suffice."
        fi
    else
        LOG "- Cloning ExtremeKernel"
        EVAL "git clone \"$EXTREMEKRNL_REPO\" --single-branch \"$KERNEL_TMP_DIR\""
    fi

    INIT_KERNEL_SUBMODULES
    APPLY_KERNEL_PATCHES

    KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not calculate the kernel cache key."
    KERNEL_COMMIT="$(git -C "$KERNEL_TMP_DIR" rev-parse --short=12 HEAD)" || ABORT "Could not determine the kernel commit."

    if KERNEL_CACHE_IS_VALID; then
        LOG "- Reusing checksum-verified kernel images from $KERNEL_COMMIT."
    else
        LOG "- Kernel cache is missing or outdated. Running the kernel build script."
        if ! BUILD_KERNEL; then
            ABORT "Kernel build failed; stale artifacts will not be reused."
            return 1
        fi

        [ -s "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img" ] || ABORT "Kernel build did not produce boot.img."
        [ -s "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img" ] || ABORT "Kernel build did not produce dtbo.img."

        # Some kernel build scripts adjust their source tree while preparing
        # KernelSU. Record the post-build state used to create these images.
        KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not update the kernel cache key."
        WRITE_KERNEL_CACHE_MANIFEST || ABORT "Could not write the verified kernel cache manifest."
    fi

    rm -f "$WORK_DIR/kernel/boot.img" "$WORK_DIR/kernel/dtbo.img" \
        "$WORK_DIR/kernel/dtbo_lte.img"
    cp -a "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img" \
        "$WORK_DIR/kernel/boot.img"
    cp -a "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img" \
        "$WORK_DIR/kernel/dtbo.img"

    [ "$(GET_FILE_SHA256 "$WORK_DIR/kernel/boot.img")" = \
        "$(GET_FILE_SHA256 "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img")" ] ||
        ABORT "Copied boot.img failed checksum verification."
    [ "$(GET_FILE_SHA256 "$WORK_DIR/kernel/dtbo.img")" = \
        "$(GET_FILE_SHA256 "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img")" ] ||
        ABORT "Copied dtbo.img failed checksum verification."

    # Copy LTE dtbo artifact if available (not for r8s or z3s)
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        local LTE_SRC="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img"
        if [[ -f "$LTE_SRC" ]]; then
            cp -a "$LTE_SRC" "$WORK_DIR/kernel/dtbo_lte.img"
            [ "$(GET_FILE_SHA256 "$WORK_DIR/kernel/dtbo_lte.img")" = \
                "$(GET_FILE_SHA256 "$LTE_SRC")" ] ||
                ABORT "Copied LTE dtbo.img failed checksum verification."
        fi
    fi

    LOG "- Installed verified kernel artifacts for $KERNEL_COMMIT."
}
# ]

REPLACE_KERNEL_BINARIES
