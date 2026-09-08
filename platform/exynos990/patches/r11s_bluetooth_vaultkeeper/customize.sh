# Persist the selected coherent stack across apply_modules.sh invocations.
# Device patches run before ROM patches, so CIDManager consumes this marker
# later and makes this module authoritative for the final system files.
mkdir -p "$WORK_DIR/configs"
printf '%s\n' "$MODPATH" > "$WORK_DIR/configs/vaultkeeper_system_stack.path"
