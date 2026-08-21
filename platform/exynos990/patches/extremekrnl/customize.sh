# [
EXTREMEKRNL_REPO="https://github.com/At30c/SSM_990v2BYEXTREME/"

GET_KERNEL_CACHE_KEY()
{
    # Include the commit, local source changes, submodules, and build arguments.
    # This invalidates the cache whenever any input that can affect an image changes.
    {
        git -C "$KERNEL_TMP_DIR" rev-parse HEAD
        git -C "$KERNEL_TMP_DIR" diff --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" diff --cached --no-ext-diff --binary
        git -C "$KERNEL_TMP_DIR" submodule status --recursive
        printf 'main: model=%s ksu=y recovery=n\n' "$TARGET_CODENAME"
        printf 'lte: model=%slte ksu=n recovery=n dtbs=y\n' "$TARGET_CODENAME"
    } | sha256sum | cut -d " " -f 1
}

KERNEL_CACHE_IS_VALID()
{
    local CACHE_FILE="$KERNEL_TMP_DIR/.unica-kernel-cache-${TARGET_CODENAME}"

    [ -f "$CACHE_FILE" ] || return 1
    [ "$(cat "$CACHE_FILE")" = "$KERNEL_CACHE_KEY" ] || return 1
    [ -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/boot.img" ] || return 1
    [ -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/dtbo.img" ] || return 1

    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        [ -f "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" ] || return 1
    fi

    return 0
}

BUILD_KERNEL()
{
    local PARENT=$(pwd)
    cd "$KERNEL_TMP_DIR"

    EVAL "./build.sh -m ${TARGET_CODENAME} -k y -r n"

    # Fixup for LTE devices
    EVAL "./build.sh -m ${TARGET_CODENAME}lte -k n -r n -d y"

    cd $PARENT
}

SAFE_PULL_CHANGES()
{
    set -eo pipefail

    local PARENT=$(pwd)

    cd "$KERNEL_TMP_DIR"

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
        cd "$PARENT"
        ABORT "Remote history has diverged (possible force-push)."
    fi

    cd "$PARENT"
}

REPLACE_KERNEL_BINARIES()
{
    local KERNEL_TMP_DIR="$KERNEL_TMP_DIR-$TARGET_PLATFORM"
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
        EVAL "git clone "$EXTREMEKRNL_REPO" --single-branch "$KERNEL_TMP_DIR" --recurse-submodules"
    fi

    KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not calculate the kernel cache key."
    KERNEL_COMMIT="$(git -C "$KERNEL_TMP_DIR" rev-parse --short=12 HEAD)" || ABORT "Could not determine the kernel commit."

    if KERNEL_CACHE_IS_VALID; then
        LOG "- Reusing cached kernel images from $KERNEL_COMMIT."
    else
        LOG "- Kernel cache is missing or outdated. Running the kernel build script."
        BUILD_KERNEL

        [ -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/boot.img" ] || ABORT "Kernel build did not produce boot.img."
        [ -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/dtbo.img" ] || ABORT "Kernel build did not produce dtbo.img."
        if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
            [ -f "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" ] || ABORT "Kernel build did not produce the LTE dtbo.img."
        fi

        # Some kernel build scripts adjust their source tree while preparing
        # KernelSU. Record the post-build state used to create these images.
        KERNEL_CACHE_KEY="$(GET_KERNEL_CACHE_KEY)" || ABORT "Could not update the kernel cache key."
        printf '%s' "$KERNEL_CACHE_KEY" > "$CACHE_FILE"
    fi

    for i in "boot" "dtbo"; do
        [[ -f "$WORK_DIR/kernel/$i.img" ]] && rm -f "$WORK_DIR/kernel/$i.img"
        cp -a "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/$i.img" "$WORK_DIR/kernel/$i.img"
    done

    # And now for the LTE DTBOs
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        cp -a "$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img" "$WORK_DIR/kernel/dtbo_lte.img"
    fi
}
# ]

REPLACE_KERNEL_BINARIES
