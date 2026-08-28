SKIPUNZIP=1

CAPEX="$WORK_DIR/system/system/apex/com.google.android.tethering_compressed.apex"
PATCH_TMP="$TMP_DIR/tethering_legacy"
DECODED="$PATCH_TMP/decoded"
PAYLOAD="$DECODED/unknown/apex_payload"

if [ ! -f "$CAPEX" ]; then
    LOGE "Tethering CAPEX not found: ${CAPEX//$WORK_DIR/}"
    return 1
fi

rm -rf "$PATCH_TMP"
mkdir -p "$PATCH_TMP"

LOG "- Extracting original Tethering APEX"
if unzip -l "$CAPEX" original_apex 2> /dev/null | grep -q "original_apex"; then
    unzip -p "$CAPEX" original_apex > "$PATCH_TMP/original.apex"
else
    # Incremental builds already contain the uncompressed APEX produced by this
    # module, even though the work-dir filename retains the _compressed suffix.
    cp -a "$CAPEX" "$PATCH_TMP/original.apex"
fi
if [ ! -s "$PATCH_TMP/original.apex" ]; then
    LOGE "Failed to extract original_apex from ${CAPEX//$WORK_DIR/}"
    return 1
fi

LOG "- Decoding original Tethering APEX"
EVAL "apktool d -j \"$(nproc)\" -o \"$DECODED\" -r \"$PATCH_TMP/original.apex\""

if ! sudo -n -v &> /dev/null; then
    LOG "\033[0;33m! Root permissions are required to unpack the Tethering APEX\033[0m"
    if ! sudo -v 2> /dev/null; then
        LOGE "Root permissions are required to unpack the Tethering APEX"
        return 1
    fi
fi

LOG "- Extracting apex_payload.img"
mkdir -p "$PAYLOAD" "$PATCH_TMP/mnt"
EVAL "sudo mount -o ro \"$DECODED/unknown/apex_payload.img\" \"$PATCH_TMP/mnt\""
EVAL "sudo cp -a -T \"$PATCH_TMP/mnt\" \"$PAYLOAD\""
sudo chown -hR "$(whoami):$(whoami)" "$PAYLOAD"
rm -rf "$PAYLOAD/lost+found"

LOG "- Recording Tethering APEX filesystem metadata"
EVAL "sudo find \"$PATCH_TMP/mnt\" | sudo xargs -I \"{}\" -P \"$(nproc)\" stat -c \"%n %u %g %a capabilities=0x0\" \"{}\" > \"$PATCH_TMP/fs_config\""
EVAL "sudo find \"$PATCH_TMP/mnt\" | sudo xargs -I \"{}\" -P \"$(nproc)\" sh -c 'echo \"\$1 \$(getfattr -n security.selinux --only-values -h --absolute-names \"\$1\")\"' \"sh\" \"{}\" > \"$PATCH_TMP/file_contexts\""
EVAL "sudo umount \"$PATCH_TMP/mnt\""
rm -rf "$PATCH_TMP/mnt" "$DECODED/unknown/apex_payload.img"

sort -o "$PATCH_TMP/file_contexts" "$PATCH_TMP/file_contexts"
sort -o "$PATCH_TMP/fs_config" "$PATCH_TMP/fs_config"
sed -i -e "s|$PATCH_TMP/mnt |/ |g" -e "s|$PATCH_TMP/mnt||g" "$PATCH_TMP/file_contexts"
sed -i -e 's|\.|\\.|g' -e 's|+|\\+|g' -e 's|\[|\\[|g' \
    -e 's|\]|\\]|g' -e 's|\*|\\*|g' "$PATCH_TMP/file_contexts"
sed -i -e "s|$PATCH_TMP/mnt | |g" -e "s|$PATCH_TMP/mnt/||g" "$PATCH_TMP/fs_config"

NETBPFLOAD="$PAYLOAD/bin/netbpfload"
EXPECTED_SHA256="cad99f3ef16dfb940e2a29b0a5061d0c8d21063604ace33877023bc78a27ad13"
PATCHED_SHA256="b4458f3107e66cff08e01de87586d2659578a4f16f09b13f846f047920eb0e61"
ACTUAL_SHA256="$(sha256sum "$NETBPFLOAD" | cut -d ' ' -f 1)"

if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
    # NetBpfLoad v0.47 aborts API 36 on kernels older than 5.4. Exynos 990 uses
    # Linux 4.19 with the required BPF functionality backported, so skip only
    # this hard version gate while preserving the real kernel version for BPF
    # program selection.
    #
    # Before: tbnz w0, #0, <Android 25Q2 requires kernel 5.4 error path>
    # After:  nop
    LOG "- Disabling NetBpfLoad Android 25Q2 kernel 5.4 version gate"
    HEX_PATCH "$NETBPFLOAD" \
        "1c070094c0160036680800f0" \
        "1c0700941f2003d5680800f0" > /dev/null
elif [ "$ACTUAL_SHA256" = "$PATCHED_SHA256" ]; then
    LOG "- NetBpfLoad Android 25Q2 kernel gate is already disabled"
else
    LOGE "Unsupported netbpfload build: $ACTUAL_SHA256"
    LOGE "Expected original/patched Android 16 build: $EXPECTED_SHA256 / $PATCHED_SHA256"
    return 1
fi

if [ "$(sha256sum "$NETBPFLOAD" | cut -d ' ' -f 1)" != "$PATCHED_SHA256" ]; then
    LOGE "netbpfload patch validation failed"
    return 1
fi

NETD_UPDATABLE="$PAYLOAD/lib64/libnetd_updatable.so"
EXPECTED_NETD_SHA256="eda006b2bc421bb2581b2193c10444b7ee158bf728034e1e57ba8425e82a6386"
PATCHED_NETD_SHA256="3ebd27e5f3a6f6c4efe04672c6b835701c8cf6cec584792e907e75d140bee67f"
ACTUAL_NETD_SHA256="$(sha256sum "$NETD_UPDATABLE" | cut -d ' ' -f 1)"

if [ "$ACTUAL_NETD_SHA256" = "$EXPECTED_NETD_SHA256" ]; then
    # libnetd_updatable performs the same API 36/kernel 5.4 check when netd
    # starts. Keeping this gate makes netd abort after NetBpfLoad successfully
    # loaded the kernel-4.19 variants of its maps and programs.
    #
    # Before: b.ls <25Q2+ kernel version unsupported error path>
    # After:  nop
    LOG "- Disabling netd Android 25Q2 kernel 5.4 version gate"
    HEX_PATCH "$NETD_UPDATABLE" \
        "1f01096be9430054e00301aa" \
        "1f01096b1f2003d5e00301aa" > /dev/null
elif [ "$ACTUAL_NETD_SHA256" = "$PATCHED_NETD_SHA256" ]; then
    LOG "- netd Android 25Q2 kernel gate is already disabled"
else
    LOGE "Unsupported libnetd_updatable build: $ACTUAL_NETD_SHA256"
    LOGE "Expected original/patched Android 16 build: $EXPECTED_NETD_SHA256 / $PATCHED_NETD_SHA256"
    return 1
fi

if [ "$(sha256sum "$NETD_UPDATABLE" | cut -d ' ' -f 1)" != "$PATCHED_NETD_SHA256" ]; then
    LOGE "libnetd_updatable patch validation failed"
    return 1
fi

LOG "- Rebuilding apex_payload.img"
"$SRC_DIR/scripts/build_fs_image.sh" "ext4" --no-avb \
    -o "$DECODED/unknown/apex_payload.img" -p "system" \
    "$PAYLOAD" "$PATCH_TMP/file_contexts" "$PATCH_TMP/fs_config" > /dev/null

rm -rf "$PAYLOAD" "$PATCH_TMP/file_contexts" "$PATCH_TMP/fs_config"

LOG "- Signing Tethering APEX payload"
SALT="$(sha256sum "$DECODED/unknown/apex_manifest.pb" | cut -d ' ' -f 1)"
EVAL "avbtool add_hashtree_footer --do_not_generate_fec --algorithm \"SHA256_RSA4096\" --hash_algorithm \"sha256\" --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --prop \"apex.key:com.android.tethering\" --salt \"$SALT\" --image \"$DECODED/unknown/apex_payload.img\""
EVAL "avbtool extract_public_key --key \"$SRC_DIR/security/avb/testkey_rsa4096.pem\" --output \"$DECODED/unknown/apex_pubkey\""

LOG "- Rebuilding uncompressed Tethering APEX"
mkdir -p "$DECODED/build/apk"
cp -a "$DECODED/original/META-INF" "$DECODED/build/apk/META-INF"
EVAL "apktool b -j \"$(nproc)\" \"$DECODED\""

BUILT_APEX="$DECODED/dist/original.apex"
if [ ! -f "$BUILT_APEX" ]; then
    LOGE "Rebuilt Tethering APEX not found"
    return 1
fi

CERT_PREFIX="aosp"
if $ROM_IS_OFFICIAL; then
    CERT_PREFIX="unica"
fi

LOG "- Signing Tethering APEX container"
EVAL "signapk -a 4096 --align-file-size \"$SRC_DIR/security/${CERT_PREFIX}_platform.x509.pem\" \"$SRC_DIR/security/${CERT_PREFIX}_platform.pk8\" \"$BUILT_APEX\" \"$BUILT_APEX.signed\""

# APEXd accepts an uncompressed APEX in place of its CAPEX. Keeping the original
# path also avoids stale filesystem metadata entries during incremental builds.
mv -f "$BUILT_APEX.signed" "$CAPEX"
rm -rf "$PATCH_TMP"

unset CAPEX PATCH_TMP DECODED PAYLOAD NETBPFLOAD EXPECTED_SHA256 PATCHED_SHA256 \
    ACTUAL_SHA256 NETD_UPDATABLE EXPECTED_NETD_SHA256 PATCHED_NETD_SHA256 \
    ACTUAL_NETD_SHA256 SALT BUILT_APEX CERT_PREFIX
