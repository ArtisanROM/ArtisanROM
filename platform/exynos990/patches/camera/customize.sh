DELETE_FROM_WORK_DIR "system" "system/lib64/libdualcam_portraitlighting_gallery_360.so"

# Add Snap libs
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-snap.samsung.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libeden_wrapper_system.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/libenn_wrapper_system.so"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libsnap_aidl.snap.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add camera libs
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-arcsoft.txt" 0 0 644 "u:object_r:system_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFace_Landmark_Engine.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFacialStickerEngine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFood.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# EVAL "echo \"libFood.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFoodDetector.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# EVAL "echo \"libFoodDetector.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libLocalTM_pcc.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing30.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfacialrestoration.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_res.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libimage_enhancement.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# if [[ "$TARGET_CODENAME" == "p3s" ]]; then
#     ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsame_source_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# fi
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
# EVAL "echo \"libsuperresolution_wrapper_v2.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
# if [[ "$TARGET_CODENAME" == "p3s" ]]; then
#     ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution_raw.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
#     ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
#     EVAL "echo \"libsuperresolutionraw_wrapper_v2.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
#     ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libuwsuperresolution.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
#     ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libuwsuperresolution_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
#     EVAL "echo \"libuwsuperresolution_wrapper_v1.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
# fi
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/public.libraries-arcsoft.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFood.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFood.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFoodDetector.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libFoodDetector.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing20.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing20Core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing20Day.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing20Tuning.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing30.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libGeoTrans10.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/vendor.samsung_slsi.hardware.geoTransService@1.0.so" 0 0 644 "u:object_r:system_lib_file:s0"

ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/liblow_light_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libhigh_res.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libsuperresolution.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libsuperresolution_raw.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"

LOG_STEP_IN "- Adding S21 (p3sxxx) SWISP models"
DELETE_FROM_WORK_DIR "vendor" "saiv/swisp_1.0"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "saiv/swisp_1.0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG "- Adding libc++_shared.so dependency for __cxa_demangle symbol"
EVAL "patchelf --add-needed \"libc++_shared.so\" \"$WORK_DIR/system/system/lib64/libMultiFrameProcessing20Core.camera.samsung.so\""

# LOG_STEP_IN "- Patching Video SVC Check"
# # Early jump after the log and abort functions when configureSVC fails
# # b LAB_001dd448 -> b LAB_001ddc24
# HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" "da4a0594e0031a2a22feff17" "da4a0594e0031a2a19000014"
# LOG_STEP_OUT

# LOG_STEP_IN "- Patching HDR10+ Check"
# # Skip HDR10+ Recording ASSERT
# # cbz this,LAB_001dde38 -> nop
# HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" "010140f90a4d0594604d0034" "010140f90a4d05941f2003d5"
# LOG_STEP_OUT

LOG_STEP_IN "- Adding blobs from other devices"
ADD_TO_WORK_DIR "e2sxxx" "system" "system/lib64/libc++_shared.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Adding S21 (p3sxxx) SingleTake models"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "p3sxxx" "system" "system/cameradata/singletake/service-feature.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "p3sxxx" "vendor" "etc/singletake"
LOG_STEP_OUT