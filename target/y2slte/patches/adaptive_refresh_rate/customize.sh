# Enable Android 16's content-aware refresh-rate selector for the S20+.
# The platform patch already provides the safe Exynos 990 timers and exposes
# the physical 48/60/96/120 Hz modes; this only replaces the source firmware's
# explicit v2=false override.
SET_PROP "vendor" "debug.sf.use_content_detection_v2" "true"

# Keep these explicit at device level to document the policy required by this
# target and avoid depending on values inherited from the source firmware.
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
