# [
EXTREMEKRNL_REPO="https://github.com/At30c/SSM_990v2BYEXTREME/"

KERNEL_MODEL="$TARGET_CODENAME"

GET_KERNEL_CACHE_KEY()
{
    # Include the commit, local source changes, submodules, and build arguments.
    # This invalidates the cache whenever any input that can affect an image changes.
    {
        git -C "$KERNEL_TMP_DIR" rev-parse HEAD
        git -C "$KERNEL_TMP_DIR" diff --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" diff --cached --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" submodule status --recursive
        printf 'main: model=%s ksu=y recovery=n\n' "$KERNEL_MODEL"
        if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
            printf 'main: model=%s ksu=n recovery=n dt_overlay=y\n' "${TARGET_CODENAME}lte"
        fi
    } | sha256sum | cut -d " " -f 1
}

KERNEL_CACHE_IS_VALID()
{
    local CACHE_FILE="$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"

    [ -f "$CACHE_FILE" ] || return 1
    [ "$(cat "$CACHE_FILE")" = "$KERNEL_CACHE_KEY" ] || return 1
    [ -f "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img" ] || return 1
    [ -f "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img" ] || return 1
    # Check LTE dtbo if applicable
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        [ -f "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" ] || return 1
    fi

    return 0
}

BUILD_KERNEL()
{
    local PARENT
    local RESULT="0"
    PARENT="$(pwd)"
    cd "$KERNEL_TMP_DIR" || return 1

    # Kernel builds are long-running and their output is needed to diagnose
    # compiler failures. Do not hide it inside EVAL's command substitution.
    LOG "- Building kernel for ${TARGET_CODENAME}"
    ./build.sh -m "$KERNEL_MODEL" -k y -r n || RESULT="$?"

    # Fixup for LTE devices: build LTE variant without KernelSU, with DT overlay
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        LOG "- Building kernel for ${TARGET_CODENAME}lte (DT overlay)"
        ./build.sh -m "${TARGET_CODENAME}lte" -k n -r n -d y || RESULT="$?"
    fi

    cd "$PARENT" || return 1
    return "$RESULT"
}

INIT_KERNEL_SUBMODULES()
{
    # The kernel repository pins the tested KernelSU-Next legacy revision.
    # Sync first so URL/branch changes from a kernel update are respected.
    EVAL "git -C \"$KERNEL_TMP_DIR\" submodule sync --recursive"
    EVAL "git -C \"$KERNEL_TMP_DIR\" submodule update --init --recursive"
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
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base @ origin/main)

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
    local CACHE_FILE="$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"
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

    KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not calculate the kernel cache key."
    KERNEL_COMMIT="$(git -C "$KERNEL_TMP_DIR" rev-parse --short=12 HEAD)" || ABORT "Could not determine the kernel commit."

    if KERNEL_CACHE_IS_VALID; then
        LOG "- Reusing cached kernel images from $KERNEL_COMMIT."
    else
        LOG "- Kernel cache is missing or outdated. Running the kernel build script."
        BUILD_KERNEL

        [ -f "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img" ] || ABORT "Kernel build did not produce boot.img."
        [ -f "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img" ] || ABORT "Kernel build did not produce dtbo.img."

        # Some kernel build scripts adjust their source tree while preparing
        # KernelSU. Record the post-build state used to create these images.
        KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not update the kernel cache key."
        printf '%s' "$KERNEL_CACHE_KEY" > "$CACHE_FILE"
    fi

    rm -f "$WORK_DIR/kernel/boot.img" "$WORK_DIR/kernel/dtbo.img" \
        "$WORK_DIR/kernel/dtbo_lte.img"
    cp -a "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/boot.img" \
        "$WORK_DIR/kernel/boot.img"
    cp -a "$KERNEL_TMP_DIR/build/out/$KERNEL_MODEL/dtbo.img" \
        "$WORK_DIR/kernel/dtbo.img"

    # Copy LTE dtbo artifact if available (not for r8s or z3s)
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        local LTE_SRC="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img"
        if [[ -f "$LTE_SRC" ]]; then
            cp -a "$LTE_SRC" "$WORK_DIR/kernel/dtbo_lte.img"
        fi
    fi
}
# ]

REPLACE_KERNEL_BINARIES
