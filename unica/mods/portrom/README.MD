PortROM
By Lindir Music

Hello, Samsung ROM Developers! Welcome to PortROM.

PortROM is a curated, privately governed audio resource project for custom Samsung ROMs, bound by the strict terms of use detailed in this document.

Implementing any part of this resource independently without crediting PortROM is considered an unauthorized implementation. Violators will be asked to remove the assets or implement the full, credited PortROM experience.

Compatibility & Naming
The name "PortROM" clearly defines our target audience. This resource is designed exclusively for ported ROMs installed on legacy devices (released prior to 2025). It is not permitted for use on stock ROMs. The ported firmware base must meet specific 2025+ technical requirements outlined in the Terms of Use below.

Features
One UI 6 Restoration: Fully restores standard One UI 6 system sounds.

Curated Samsung Archives: Collects all special or discarded ringtones and notifications released from 2022 (Galaxy S22 series) onward. This archive will be continuously updated with new sounds.

Apple Sound Integration: Includes Apple ringtones and notification sounds, fully complete with synchronized vibration support. Once fully ported, these will be bundled into a dedicated, selectable "Apple" sound theme in settings.

ExtremeOS Legacy Sounds: Bundles the trademark ExtremeOS sounds by Lindir Music, including the modified spaceline notification, as well as custom power-on and power-off sounds.

Custom Sound Themes: Introduces a new system sound theme, selectable in Settings, called "PortROM". This encompasses the ExtremeOS ringtones, notifications, and custom system UI sounds.

Terms of Use
I. The "OTF" Audio Requirement (Crucial)
Starting with the S25 series in 2025, Samsung introduced a new core audio system logic that we have dubbed "ON-The-Fly AI Audio DSP" (OTF).

How it works: A machine learning model integrated into core services, the Android framework, and core .jar base folders dictates real-time audio output. It actively controls internal compressors, saturators, phasers, gates, and limiters. (Note: This is strictly the underlying DSP logic and is NOT to be confused with user-facing audio features). This OTF logic cannot be manually controlled by the user. It drastically improves the output of the internal phone speaker, connected Samsung headphones/speakers, and other audio-capable devices.

The Rule: Because of the substantial audio improvements OTF brings, PortROM is strictly restricted from being used on any ROM base that does not support OTF AI Audio. Your ported base must be from an S25 series (including Edge and FE), an A-series (though OTF is limited here), or any S/Z series device released after 2025. You must meet these OTF base requirements before requesting access to PortROM and before implementing it on a legacy device.

II. Distribution
As an approved ROM developer utilizing the PortROM resource, you are strictly prohibited from sharing, distributing, selling, or publicly hosting PortROM. Doing so will result in the immediate revocation of your access.

III. Maintaining Access
Your access to PortROM is contingent upon your continued support of OTF Audio on your One UI port. If you drop OTF support (e.g., by downgrading the firmware base of your device), you must immediately cease using the PortROM resource.

IV. Community Surveillance
PortROM relies on the vigilance of both developers and users to maintain its integrity. We ask our implementers and users to actively report any custom ROMs that utilize PortROM features without properly crediting Lindir Music or PortROM, or any ROMs illegitimately using the resource without supporting the required OTF Audio logic.

Changelog
V1.0.2:

Added 2026 calm ringtones extracted from the S26 Ultra.

V1.0.1:

Added Galaxy Watch sounds and various lost ringtones from sync-with-vibration supported devices (2022-2024). These were provided via the Resilio Sync archive "Phone Ringtones" (a blind community initiative).

Added Apple sounds: Radiate, Reflection, and Shelter.

Switched the synchronized vibration base to the S23 Ultra.

V1.0.0:

Initial release.

Usage Instructions
Replace your existing /media/audio directory with the folder provided in this resource.

Implement the custom power-off and power-on sounds into your base.

Edit your system's settings.apk file to add the new entries for our custom sound schemes.

Recompile, test, and enjoy!

Supported Developers
A special thanks to the authorized developers currently supporting this project:

Oskar Rottmüller (OsRot61)

Giulia (android_artisan)

Contact Us
For access requests, reporting unauthorized usage, or general inquiries, you can reach us on Telegram at: https://t.me/LindirContactTG

Thank you for respecting the rules and using PortROM!
