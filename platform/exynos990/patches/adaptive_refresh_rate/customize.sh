# Enable Android 16's content-aware refresh-rate selector on Exynos 990
# devices whose panels support high refresh rates. The Galaxy Note20 (c1s)
# has a 60 Hz panel and must retain its stock policy.
# The platform patch already provides the safe Exynos 990 timers and exposes
# the physical 48/60/96/120 Hz modes; this only replaces the source firmware's
# explicit v2=false override.
if [[ "$TARGET_CODENAME" == "c1s" ]]; then
    LOG "- Keeping the stock 60 Hz refresh-rate policy for c1s"
    return 0
fi

SET_PROP "vendor" "debug.sf.use_content_detection_v2" "true"

# Keep these explicit at platform level to document the policy and avoid
# depending on values inherited from the source firmware.
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
