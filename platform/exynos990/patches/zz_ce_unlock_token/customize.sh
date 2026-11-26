# LockSettingsService passes the Gatekeeper HAT as an auth token to
# vold.unlockCeStorage() when ro.product.first_api_level <= 30 (the S20
# series ships with 29). The S926B vold rejects any token
# ("Vold doesn't use auth tokens, but non-empty token passed to
# unlockUserKey." -> EINVAL), so with /data encrypted the user never
# unlocks and the device stays on "Starting Android...". Take the token-less
# path, which is what this vold expects.
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0001-Do-not-pass-auth-token-to-vold-unlockCeStorage.patch"
