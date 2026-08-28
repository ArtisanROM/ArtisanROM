/*
 * Compatibility shim for Android 12 audio HIDL wrappers on the Exynos 990
 * Android 11 VNDK. This helper only records legacy HIDL transport errors in
 * newer libhidlbase; omitting the log does not change HAL behaviour.
 */
__attribute__((visibility("default")))
void android_hardware_details_errorWriteLog(int tag, const char *message)
        __asm__("_ZN7android8hardware7details13errorWriteLogEiPKc");

void android_hardware_details_errorWriteLog(int tag, const char *message)
{
    (void) tag;
    (void) message;
}
