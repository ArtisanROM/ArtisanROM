# ArtisanROM changelog

# 3.1.1
- Fix Bluetooth on 9820 (thx @dupazlasu/@milxnaq)
- Update kernels to KSU Next v3.2.0
- Debloat SamsungTTS completely.
- Keep EroFS Partitions

# 3.1.0
- Add S10 Series (Exynos9820)
- Add Custom ExtremeROM Ringtones and Startup/Shutdown sounds (thx @Ronan & Lindir Music)
- Update KernelSU-Next version to 3.1.0 (thx @Mesazane)
- Fix Boot Animation
- Fix 120hz refresh rate
- Add Software Update button in Settings app to directly open the Updater App (thx @salvogiangri)
- Add ArtisanROM Settings in Updater app (NEW Settings screen to turn features on or off.)
- Add Vulkan Rendering (Experimental) (thx @salvogiangri)
- Switch to EXT4
- Update Viper4Android to latest
- Fix Termux Crash on all 990 devices
- Updated base firmware to S25 FE March Security Patch
- Add Unlimited Google Photos storage spoof (thx @salvogiangri)
- Rebrand to ArtisanROM
- Start to sign Official Releases
- Remove LED case support
- Debloat all SamsungTTS

# 3.0.7
- Fix USB Audio
- Add Multi User Support
- Fix Screen Record

# 3.0.6
- This update was made possible thx to @Ghasemzadehfard-Dev
- Fix SvstemUI crash on r8s (thx @GhasemzadehFard-Dev)
- Fix Termux Crash on r8s (thx @chasemzadehFard-Dev)
- Add RAM Plus fully to r8s (thx @GhasemzadehFard-Dev)
- Add S26U fake device image
- Updated base firmware to S25 FE February Security Patch

# 3.0.5
- Add Viper4Android
- Add more apps to debloat
- Fix RAM Plus (thx @GhasemzadehFard-Dev)
- Fix termux reboot on kill (thx @GhasemzadehFard-Dev)
- Fix Face Recognition on r8s (thx @GhasemzadehFard-Dev)
- Bypass CSC and fix Hiya (thx @GhasemzadehFard-Dev)
- Keep optics and prism EXT4 (thx @GhasemzadehFard-Dev)
- This update would not be possible without @GhasemzadehFard-Dev

# 3.0.1
- Fixed reboot on call end (thx @GhasemzadehFard-Dev)
- Add logo and fix bugs in the updater app
- Add and enable native smart call and hiya globally throughout the ROM
- Remove Enhanced Open option from hotspot settings as it caused issues on exynos 990 devices

# 3.0.0
- Switch to S25FE base
- Upgrade to OneUI 8.0
- Fix Motion photo (thx @riccigti)
- Fixed 120HZ
- Fix Extra Brightness not doing anything
- Add UN1CA patches to improve experience
- Add ArtisanROM Updater (Allows OTA updates without needing a pc to sideload or doing it in TWRP [Requires the ROM to already be installed])

# 2.6.1
- Updated build system (thx @Ksawlii)
- Added ASCII art in the installer (thx @bkurt)
- Switched to ExtremeROM Certificate for modified APKs and main installer ZIP (thx @salvogiangri)
- Added ExtremeROM Branding in Settings
- Brought back 4-digit OK PIN Patch (thx @Ocin4ever)
- Fixed 16MP UW on S10 Series (thx @Mesazane)
- Fixed Heart Rate Monitor sensor on S10 Series
- Fixed Camera on Note 20
- Fixed Bluetooth on S10 Series and S20 FE
- Fixed Portrait Video on S22 Series (thx @dupazlasu)
- Fixed Samsung Camera app icon for S10 Series (thx @Ocin4Ever)
- Updated base firmware to S24 FE August Security Patch

# 2.6.0
- Fixed MyFilter for exynos2200 (thx @dupazlasu)
- Switched to OneUI 6.1.1 camera for exynos9820 (fixed watermark, filters, lockscreen gallery, double videos in gallery, post-processing and more) (thx @PeterKnecht)
- Fixed back portrait mode for exynos9820 (finally!)
- Bluetooth enhancements for all platforms
- Fixed SingleTake in camera for 9820/990/2100 (thx @szucsy92)
- Fixed Adaptive Refresh Rate Flickering issue for S20 series
- Added Adaptive Refresh Rate for S20 FE and S21 FE
- Fixed AirCommand crash for S21 Ultra
- Removed Detail Enhancer button for unsupported models (S21/S21+) (thx @maximusXZ)
- Fixed Detail Enhancer for S21 Ultra
- Fixed zoom photos on S21 FE
- Fixed Ultra Wideband on Note20 Ultra
- Fixed Motion Photo on S20/N20
- Fixed Link to Windows feature
- Added AppLock
- Fixed progress bar in installer
- Switched to EroFS SYSTEM partition
- Fixed SDCard and OTG in TWRP for Exynos 9820/990
- Updated all OdinPacks

# 2.5.0
- Switched base to S24 FE (S721BXXS6BYF5)
- HEAVILY improved performance, general smoothness, battery and thermals
- Added missing SPen APKs for Note20
- Fixed camera crashes on Note20
- Fixed front camera animations
- Fixed Heart Rate Monitor in Samsung Health on S10
- Fixed NowBar position for S10, S20FE and S21FE models
- Fixed Gemini black bar
- Added support for: r0s/g0s/b0s (exynos2200/s5e9925)
- Updated Security Patch Level and all proprietary blobs used

# 2.0.0
- Added Adaptive Brightness feature
- Added Adaptive Refresh Rate for S20
- Added Extra Dim feature for S10 (thanks @Ocin4Ever)
- Added heavier DeKnoxing patch (thanks @PeterKnecht93)
- Added LATAM CSC support (thanks @Yagzie)
- Added Multi-User support (thanks @nalz0)
- Added OneUI 7 LPM animation
- Added support for: r8s (exynos990), o1s/t2s/p3s/r9s (exynos2100)
- Added Ultrasonic FOD Animation for Optical FODs (thanks @Ksawlii)
- Added Video LOG feature (might not be fully functional)
- Build system heavily optimized and improved for developers
- Disabled useless Samsung ASKS security (thanks @salvogiangri)
- Enabled 5GHz hotspot for all countries
- Enabled APK Downgrading (thanks @salvogiangri)
- Enabled IncrementalFS
- Enabled navigation gestures by default
- Enabled SideKey button as Power button by default
- Enabled UserFaultFD Garbage Collector for ARTD
- Enabled Vulkan Graphical Rendering API for 9820 and 990 by default
- Fixed 0.5x UW camera for S10 (using OneUI 4 apk) (thanks @duhansysl/@Anan1211)
- Fixed Air Actions on Note 20 (thanks @CodeMalaya)
- Fixed aperture switching for S10 (thanks @duhansysl/@Anan1211)
- Fixed BASIC Play Integrity attestation without any modules (thanks @tsn/@salvogiangri)
- Fixed brightness issues on S10 and Note20
- Fixed Camera Filters
- Fixed camera zoom levels on Note20 (thanks @Ocin4Ever/@Mesazane)
- Fixed Device Controls / Smart Things
- Fixed DVFS voltage configs
- Fixed ENGMODE HAL crashing
- Fixed FrameRate and Motion Smoothness configuration on 60Hz-only models
- Fixed Heart Rate Monitor for S10 (only works in third-party apps)
- Fixed low brightness on boot animation (thanks @BotchedRPR)
- Fixed NFC LED cases (thanks @VladBinti)
- Fixed power button animation (Thanks @RenoxTV)
- Fixed purchases in Samsung apps
- Fixed resolution on 1080p devices (thanks @Ocin4Ever)
- Fixed rounded corners overlay for all devices
- Fixed some camera crashes on Note20 devices
- Fixed some display glitches on S10
- Fixed Super HDR feature
- Fixed SuperFast Charging on supported devices
- Fixed USB OTG on exynos990
- Fixed VAULTKEEPER HAL crashing on exynos9820
- Fixed washed out display colors
- Increased debloat list (thanks @PeterKnecht93)
- Removed bootlogo warning
- Removed Google Telemetry apps (thanks @NhatVo)
- Removed incompatible vibraton setting options
- Removed incompatible Wi-Fi Hotspot options (thanks @PeterKnecht93)
- Removed kSMBd Storage Share on 9820/990
- Semi-fixed ExpertRAW for Note20 Ultra/S20 Ultra
- Set default TCP Congestion Algorithm to BBRv2
- Spoofed stock device model for user apps (thanks @Ocin4Ever/@salvogiangri)
- Updated KernelSU Next Driver + Manager
- Updated Note20 OdinPacks to G binary
- Updated source firmware to S938BXXS4AYF1 (June SPL)
- Countless other small optimizations for the best UX experience

## 1.0.0
- Initial release
- Support for beyond0lte, beyond1lte, beyond2lte, beyondx, x1s, y2s, z3s, c1s, c2s
