# Android 16 expects a matching /data/system/frp_secret whenever the
# persistent partition already contains the new FRP magic.  A clean port
# installation can preserve that partition while wiping /data, leaving the
# service permanently active even after Setup Wizard provisions the device.
# The system Package Installer then rejects every interactive installation.
#
# Apply this consistently to every port, including CI builds: leaving
# ro.frp.pst unset prevents the incompatible PersistentDataBlockService from
# starting and matches the manually verified workaround.
SET_PROP "vendor" "ro.frp.pst" --delete
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "system" "ro.frp.pst" --delete
SET_PROP "system_ext" "ro.frp.pst" --delete
SET_PROP "odm" "ro.frp.pst" --delete
