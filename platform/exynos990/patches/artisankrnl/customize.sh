# [
EXTREMEKRNL_REPO="https://github.com/Android-Artisan/android_kernel_samsung_exynos990"

BUILD_KERNEL()
{
    local PARENT=$(pwd)
    
    # Ensure we are in the correct directory
    cd "$KERNEL_TMP_DIR" || ABORT "BUILD_KERNEL: Cannot find $KERNEL_TMP_DIR"

    LOG "- Running build for ${TARGET_CODENAME}"
    EVAL "./build.sh -m ${TARGET_CODENAME} -k y -r n"

    # Fixup for LTE devices
    LOG "- Running build for ${TARGET_CODENAME}lte"
    EVAL "./build.sh -m ${TARGET_CODENAME}lte -k n -r n -d y"

    cd "$PARENT"
}

SAFE_PULL_CHANGES()
{
    set -eo pipefail
    local PARENT=$(pwd)

    cd "$KERNEL_TMP_DIR" || ABORT "SAFE_PULL: Directory missing"
    EVAL "git fetch origin"

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base @ origin/main)

    if [[ "$LOCAL" == "$REMOTE" ]]; then
        LOG "- Local branch is up-to-date."
    elif [[ "$LOCAL" == "$BASE" ]]; then
        LOG "- Fast-forwarding."
        EVAL "git pull --ff-only"
    else
        LOGW "- Local branch diverged or ahead. Resetting to remote."
        git reset --hard origin/main
    fi

    cd "$PARENT"
}

REPLACE_KERNEL_BINARIES()
{
    # 1. Define the directory name based on your requirement
    # Using 'out' as the parent folder
    KERNEL_TMP_DIR="out/kernel_tmp-${TARGET_PLATFORM}"

    # 2. Check if the directory is missing
    if [[ ! -d "$KERNEL_TMP_DIR" ]]; then
        LOG "- Kernel directory missing. Cloning into $KERNEL_TMP_DIR..."
        # Ensure 'out' exists before cloning
        mkdir -p -- "out"
        EVAL "git clone --branch bpf111 --single-branch --recurse-submodules \"$EXTREMEKRNL_REPO\" \"$KERNEL_TMP_DIR\"" || ABORT "Clone failed"
    fi

    # 3. Repository Sync
    if [[ -d "$KERNEL_TMP_DIR/.git" ]]; then
        cd "$KERNEL_TMP_DIR" || exit
        LOG "- Syncing source code..."
        git fetch --all
        git reset --hard FETCH_HEAD
        cd - > /dev/null || exit
    else
        ABORT "Directory exists but is not a git repo: $KERNEL_TMP_DIR"
    fi

    # 4. Execute Build
    LOG "- Starting kernel build process."
    BUILD_KERNEL

    # 5. Artifact Management
    [[ ! -d "$WORK_DIR/kernel" ]] && mkdir -p -- "$WORK_DIR/kernel"

    for i in "boot" "dtbo"; do
        local SRC="$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/$i.img"
        if [[ -f "$SRC" ]]; then
            rm -f "$WORK_DIR/kernel/$i.img"
            mv -f "$SRC" "$WORK_DIR/kernel/$i.img"
        else
            LOGW "Artifact $i.img not found at $SRC"
        fi
    done

    # LTE Artifacts
    if [[ "$TARGET_CODENAME" != "r8s" ]] && [[ "$TARGET_CODENAME" != "z3s" ]]; then
        local LTE_SRC="$KERNEL_TMP_DIR/build/out/${TARGET_CODENAME}lte/dtbo.img"
        if [[ -f "$LTE_SRC" ]]; then
            mv -f "$LTE_SRC" "$WORK_DIR/kernel/dtbo_lte.img"
        fi
    fi
}
# ]

REPLACE_KERNEL_BINARIES
