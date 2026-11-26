# The S926B (One UI 8.5) SurfaceFlinger always selects the Sysprop kernel idle
# timer controller for the primary display ("Enabling KernelIdleTimer for main
# display"), skipping the AOSP capability/sysprop checks. Exynos 990 S20
# panels have no kernel idle timer, so nothing ever lowers the refresh rate:
# with an app static the display stays at 120 Hz (only explicit layer votes,
# e.g. the lock screen, bring it down).
#
# Turn the "primary display" b.ne into an unconditional branch so the AOSP
# path runs: no HWC idle timer on HIDL and support_kernel_idle_timer=false,
# so SurfaceFlinger uses its own idle timer and switches to 48/60 Hz.
# Tested on x1s (SM-G980F): static Settings 120 Hz -> 48 Hz, touch -> 120 Hz.
case "$TARGET_CODENAME" in
    x1s|y2s|z3s) ;;
    *)
        LOG "- Skipping SurfaceFlinger idle timer patch for $TARGET_CODENAME"
        return 0
        ;;
esac

HEX_PATCH "$WORK_DIR/system/system/bin/surfaceflinger" \
    "00013fd69f0200ebe101005441d8ffb021683c91" \
    "00013fd69f0200eb0f00001441d8ffb021683c91"

# Same timers the r8s target uses for its Exynos 990 panel. Keep them in
# /vendor/default.prop next to the content detection prop: the legacy
# BACKPORT_SF_PROPS step re-inserts that prop before set_idle_timer_ms in
# default.prop, so the timers must live in the same file.
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
for SF_TIMER in "set_touch_timer_ms=300" "set_idle_timer_ms=250"; do
    SET_PROP "vendor" "ro.surface_flinger.${SF_TIMER%%=*}" --delete
    EVAL "sed -i \"/^ro.surface_flinger.use_content_detection_for_refresh_rate=/a ro.surface_flinger.$SF_TIMER\" \"$WORK_DIR/vendor/default.prop\""
done
unset SF_TIMER
