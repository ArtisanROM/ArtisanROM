# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# UN1CA debloat list
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Modes and Routines
SYSTEM_DEBLOAT+="
system/priv-app/Routines
"

# SmartThings
SYSTEM_DEBLOAT+="
system/priv-app/SmartThingsKit
"

# Wi-Fi Tips
SYSTEM_DEBLOAT+="
system/app/WifiGuider
"

# Auto Blocker
SYSTEM_DEBLOAT+="
system/app/Rampart
"

# Samsung Defex policy
SYSTEM_DEBLOAT+="
dpolicy_system
"
VENDOR_DEBLOAT+="
etc/dpolicy
"

# Samsung PROCA certificate DB
SYSTEM_DEBLOAT+="
system/etc/proca.db
"

# Samsung SIM Unlock
SYSTEM_DEBLOAT+="
system/bin/ssud
system/etc/init/ssu_$(GET_PROP "system" "ro.product.system.name").rc
system/etc/init/ssu.rc
system/etc/permissions/privapp-permissions-com.samsung.ssu.xml
system/etc/sysconfig/samsungsimunlock.xml
system/lib64/android.security.securekeygeneration-ndk.so
system/lib64/libssu_keystore2.so
system/priv-app/SsuService
"

# Recovery restoration script
VENDOR_DEBLOAT+="
recovery-from-boot.p
bin/install-recovery.sh
etc/init/vendor_flash_recovery.rc
"

# PDP apps
SYSTEM_DEBLOAT+="
system/preload
"

truncate -s 0 "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"

# eSIM
[[ "$TARGET_COMMON_SUPPORT_EMBEDDED_SIM" == "false" ]] && SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml
system/etc/permissions/privapp-permissions-com.samsung.euicc.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.euicc.xml
system/priv-app/EsimKeyString
system/priv-app/EuiccService
"

# SmartFPSAdjuster
[ "$TARGET_LCD_CONFIG_HFR_MODE" -lt "1" ] && SYSTEM_DEBLOAT+="
system/priv-app/IntelligentDynamicFpsService
"

# Application recommendations
SYSTEM_DEBLOAT+="
system/app/MAPSAgent
"

# Carrier / Enterprise / Debug bloat
SYSTEM_DEBLOAT+="
system/app/CarrierDefaultApp
system/app/ccinfo
system/app/Fast
system/app/SimAppDialog
system/priv-app/ImsLogger
system/priv-app/OdaService
system/priv-app/OMCAgent5
system/etc/permissions/privapp-permissions-com.samsung.android.fast.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.omcagent.xml
system/etc/permissions/privapp-permissions-com.samsung.oda.service.xml
system/etc/permissions/privapp-permissions-com.sec.imslogger.xml
system/etc/permissions/privapp-permissions-com.skms.android.agent.xml
system/etc/permissions/signature-permissions-com.samsung.android.app.parentalcare.xml
system/etc/sysconfig/config-com.samsung.android.app.parentalcare.xml
"

# AppUpdateCenter
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.updatecenter.xml
system/priv-app/AppUpdateCenter
"

# BCService
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.sec.bcservice.xml
system/priv-app/BCService
"

# Gaming Hub
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.game.gamehome.xml
system/priv-app/GameHome
"

ADD_TO_WORK_DIR "pa2qxxx" "system" \
    "system/etc/permissions/signature-permissions-com.samsung.android.game.gamehome.xml" \
    0 0 644 "u:object_r:system_file:s0"

# Gemini shortcut
PRODUCT_DEBLOAT+="
app/BardShell
"

# Gmail
PRODUCT_DEBLOAT+="
app/Gmail2
"

# Google Assistant shortcut
PRODUCT_DEBLOAT+="
app/AssistantShell
"

# Google Chrome
PRODUCT_DEBLOAT+="
app/Chrome
"

# Google Duo
PRODUCT_DEBLOAT+="
app/DuoStub
"

# Google Speech Services
PRODUCT_DEBLOAT+="
app/SpeechServicesByGoogle
"

# Google Maps
PRODUCT_DEBLOAT+="
app/Maps
"

# Google PAI (Play Autoinstall)
SYSTEM_DEBLOAT+="
system/app/PlayAutoInstallConfig
"

# Language packs
SYSTEM_DEBLOAT+="$(find "$WORK_DIR/system" -type d -name "*TTSVoice*" | sed "s|$WORK_DIR/system/||g")"

# Main TTS app (kept for SMT.LanguageProvider content provider,
# needed by Galaxy AI language pack downloads)
# SYSTEM_DEBLOAT+="
# system/app/SamsungTTS
# "

# Samsung Kids
SYSTEM_DEBLOAT+="
system/etc/permissions/signature-permissions-com.sec.android.app.kidshome.xml
system/app/KidsHome_Installer
"

# Samsung Notes
SYSTEM_DEBLOAT+="
system/app/Notes40
"

# Bixby
SYSTEM_DEBLOAT+="
system/priv-app/Bixby
system/app/BixbyWakeup
system/app/VisionIntelligence3.7
system/app/VisualCloudCore
system/etc/preferred-apps/com.samsung.android.bixby.agent.xml
system/etc/permissions/privapp-permissions-com.samsung.android.bixby.agent.xml
system/etc/permissions/privapp-permissions-com.samsung.android.bixby.wakeup.xml
system/etc/permissions/signature-permissions-com.samsung.android.bixby.agent.xml
system/etc/sysconfig/bixbyagent.xml
"

# LED Cover Service
[ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_NFC_LED_COVER_LEVEL")" -lt "30" ] && SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.sec.android.cover.ledcover.xml
system/priv-app/LedCoverService
"

# Spen
SYSTEM_DEBLOAT+="
system/app/AirGlance
system/app/LiveDrawing
system/etc/default-permissions/default-permissions-com.samsung.android.service.aircommand.xml
system/etc/permissions/privapp-permissions-com.samsung.android.app.readingglass.xml
system/etc/permissions/privapp-permissions-com.samsung.android.service.aircommand.xml
system/etc/permissions/privapp-permissions-com.samsung.android.service.airviewdictionary.xml
system/etc/public.libraries-smps.samsung.txt
system/etc/sysconfig/airviewdictionaryservice.xml
system/lib64/libsmpsft.smps.samsung.so
system/media/audio/pensounds
system/priv-app/AirCommand
system/priv-app/AirReadingGlass
system/priv-app/SmartEye
"

# Link to Windows
# Replace full apk with stub apk to save space
SYSTEM_DEBLOAT+="
system/priv-app/YourPhone_P1_5
system/priv-app/LinkToWindowsService
"

# Live Transcribe
SYSTEM_DEBLOAT+="
system/app/LiveTranscribe
system/etc/sysconfig/feature-a11y-preload.xml
"

# Meta
SYSTEM_DEBLOAT+="
system/app/FBAppManager_NS
system/etc/default-permissions/default-permissions-meta.xml
system/etc/permissions/privapp-permissions-meta.xml
system/etc/sysconfig/meta-hiddenapi-package-allowlist.xml
system/priv-app/FBInstaller_NS
system/priv-app/FBServices
"

# Microsoft OneDrive
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.microsoft.skydrive.xml
system/priv-app/OneDrive_Samsung_v3
"

# My Galaxy
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.mygalaxy.service.xml
system/etc/sysconfig/preinstalled-packages-com.mygalaxy.service.xml
system/priv-app/MyGalaxyService
"

# Samsung Analytics
SYSTEM_DEBLOAT+="
system/app/DsmsAPK
system/etc/permissions/privapp-permissions-com.samsung.android.dqagent.xml
system/etc/permissions/privapp-permissions-com.sec.android.diagmonagent.xml
system/etc/permissions/privapp-permissions-com.sec.android.soagent.xml
system/priv-app/DeviceQualityAgent36
system/priv-app/DiagMonAgent95
system/priv-app/SOAgent76
"

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_CONTEXTSERVICE_ENABLE_SURVEY_MODE" --delete

# Samsung AR Emoji
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.sec.android.mimage.avatarstickers.xml
system/etc/permissions/privapp-permissions-com.samsung.android.aremojieditor.xml
system/etc/permissions/privapp-permissions-com.sec.android.mimage.avatarstickers.xml
system/etc/permissions/signature-permissions-com.sec.android.mimage.avatarstickers.xml
system/priv-app/AREmoji
system/priv-app/AREmojiEditor
system/priv-app/AvatarEmojiSticker
system/priv-app/StickerFaceARAvatar
"

# Samsung Calendar
SYSTEM_DEBLOAT+="
system/app/SamsungCalendar
system/etc/permissions/signature-permissions-com.samsung.android.calendar.xml
"

# Samsung Clock
SYSTEM_DEBLOAT+="
system/app/ClockPackage
system/etc/permissions/signature-permissions-com.sec.android.app.clockpackage.xml
"

# Samsung Free
SYSTEM_DEBLOAT+="
system/app/MinusOnePage
system/etc/permissions/signature-permissions-com.samsung.android.app.spage.xml
"

# Samsung Language Core
SYSTEM_DEBLOAT+="
system/etc/permissions/signature-permissions-com.samsung.android.offline.languagemodel.xml
system/priv-app/OfflineLanguageModel_stub
"

# Google Messages
PRODUCT_DEBLOAT+="
priv-app/Messages
"

# Samsung Pass
SYSTEM_DEBLOAT+="
system/app/SamsungPassAutofill_v1
system/etc/init/samsung_pass_authenticator_service.rc
system/etc/permissions/authfw.xml
system/etc/permissions/privapp-permissions-com.samsung.android.authfw.xml
system/etc/permissions/privapp-permissions-com.samsung.android.samsungpass.xml
system/etc/permissions/signature-permissions-com.samsung.android.samsungpass.xml
system/etc/permissions/signature-permissions-com.samsung.android.samsungpassautofill.xml
system/etc/sysconfig/samsungauthframework.xml
system/etc/sysconfig/samsungpassapp.xml
system/priv-app/AuthFramework
system/priv-app/SamsungPass
"

# Samsung Reminder
SYSTEM_DEBLOAT+="
system/app/SmartReminder
system/etc/permissions/signature-permissions-com.samsung.android.app.reminder.xml
"

# Samsung Visit In
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.ipsgeofence.xml
system/priv-app/IpsGeofence
"

# Samsung Wallet
SYSTEM_DEBLOAT+="
system/etc/init/digitalkey_init_ble_tss2.rc
system/etc/init/digitalkey_init_uwb_tss2.rc
system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml
system/etc/permissions/privapp-permissions-com.samsung.android.carkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml
system/etc/permissions/privapp-permissions-com.samsung.android.dkey.xml
system/etc/permissions/privapp-permissions-com.samsung.android.spayfw.xml
system/etc/permissions/signature-permissions-com.samsung.android.spay.xml
system/etc/permissions/signature-permissions-com.samsung.android.spayfw.xml
system/etc/sysconfig/digitalkey.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.dkey.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.spayfw.xml
system/priv-app/DigitalKey
system/priv-app/PaymentFramework
system/priv-app/SamsungCarKeyFw
"
SYSTEM_EXT_DEBLOAT+="
framework/org.carconnectivity.android.digitalkey.rangingintent.jar
framework/org.carconnectivity.android.digitalkey.secureelement.jar
"

# Search engine selector
PRODUCT_DEBLOAT+="
overlay/GmsConfigOverlaySearchSelector.apk
priv-app/SearchSelector
"

# SettingsHelper
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.settingshelper.xml
system/etc/sysconfig/settingshelper.xml
system/priv-app/SHClient
"

# Smart Touch Call
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.visualars.xml
system/etc/permissions/privapp-permissions-com.samsung.android.visualars.xml
system/priv-app/SmartTouchCall
"

# Smart Tutor
SYSTEM_DEBLOAT+="
system/hidden/SmartTutor
"

SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_SMARTTUTOR_PACKAGES_PATH" --delete

# Software update
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.wssyncmldm.xml
system/priv-app/FotaAgent
"

# SVC Agent
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.svcagent.xml
system/priv-app/SVCAgent
"

# SVoiceIME
SYSTEM_DEBLOAT+="
system/priv-app/SVoiceIME
"

# Voice Access
SYSTEM_DEBLOAT+="
system/app/VoiceAccess
system/etc/sysconfig/feature-a11y-preload-voacc.xml
"

# YouTube
PRODUCT_DEBLOAT+="
app/YouTube
"
