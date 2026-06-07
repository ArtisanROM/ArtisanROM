# [
LK3RD_REPO="https://github.com/Android-Artisan/lk3rd"

BUILD_LK3RD()
{
    PARENT=$(pwd)

    # Ensure we are in the correct directory
    cd "$LK3RD_TMP_DIR" || ABORT "BUILD_LK3RD: Cannot find $LK3RD_TMP_DIR"

    LOG "- Running build for ${TARGET_CODENAME}"
    EVAL "./build.sh ${TARGET_CODENAME} -u -v n"

    cd "$PARENT"
}

SAFE_PULL_CHANGES()
{
    set -eo pipefail
    PARENT=$(pwd)

    cd "$LK3RD_TMP_DIR" || ABORT "SAFE_PULL: Directory missing"
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

ADD_LK3RD_BINARIES()
{
    # 1. Define the directory name based on your requirement
    # Using 'out' as the parent folder
    LK3RD_TMP_DIR="out/lk3rd_tmp-${TARGET_PLATFORM}"

    # 2. Check if the directory is missing
    if [[ ! -d "$LK3RD_TMP_DIR" ]]; then
        LOG "- lk3rd directory missing. Cloning into $LK3RD_TMP_DIR..."
        mkdir -p -- "out"
        EVAL "git clone --branch dev --single-branch --recurse-submodules \"$LK3RD_REPO\" \"$LK3RD_TMP_DIR\"" || ABORT "Clone failed"
    fi

    # 3. Repository Sync
    if [[ -d "$LK3RD_TMP_DIR/.git" ]]; then
        cd "$LK3RD_TMP_DIR" || exit
        LOG "- Syncing source code..."
        git fetch --all
        git reset --hard FETCH_HEAD
        cd - > /dev/null || exit
    else
        ABORT "Directory exists but is not a git repo: $LK3RD_TMP_DIR"
    fi

    # 4. Execute Build
    LOG "- Starting lk3rd build process."
    BUILD_LK3RD

    # 5. Artifact Management
    [[ ! -d "$WORK_DIR/kernel" ]] && mkdir -p -- "$WORK_DIR/kernel"

    SRC="$LK3RD_TMP_DIR/build/${TARGET_CODENAME}/lk3rd-${TARGET_CODENAME}.img"

    if [[ -f "$SRC" ]]; then
        rm -f "$WORK_DIR/kernel/lk3rd.img"
        mv -f "$SRC" "$WORK_DIR/kernel/lk3rd.img"
    else
        LOGW "Artifact lk3rd-${TARGET_CODENAME}.img not found at $SRC"
    fi
}

ADD_LK3RD_BINARIES
# ]
