DECODE_APK "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk"

LOG "- Enabling navigation bar type settings step"
SETUPWIZARD_APK="$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk"
NAV_STEP_FILE="$(find "$SETUPWIZARD_APK" -type f -name '*.smali' \
    -exec grep -lF '"navigationbar_setting"' {} + \
    | grep -v '/com/sec/android/app/SecSetupWizard/SecSetupWizardActivity.smali$' | sed -n '1p')"
[ "$NAV_STEP_FILE" ] || ABORT "Navigation bar setup step implementation not found"
NAV_STEP_METHOD="$(awk '/^\.method/{method=$0} /"navigationbar_setting"/{print method; exit}' "$NAV_STEP_FILE" \
    | sed -E 's/^\.method ([^ ]+ )*//')"
NAV_STEP_FILE="${NAV_STEP_FILE//$SETUPWIZARD_APK\//}"
SMALI_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
    "$NAV_STEP_FILE" "replace" \
    "$NAV_STEP_METHOD" \
    "navigationbar_setting" \
    "this_string_does_not_exist" \
    > /dev/null
SETUPWIZARD_ACTIVITY="smali/com/sec/android/app/SecSetupWizard/SecSetupWizardActivity.smali"
SETUPWIZARD_ACTIVITY_METHOD="$(awk '/^\.method/{method=$0} /"navigationbar_setting"/{print method; exit}' \
    "$SETUPWIZARD_APK/$SETUPWIZARD_ACTIVITY" | sed -E 's/^\.method ([^ ]+ )*//')"
SMALI_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
    "$SETUPWIZARD_ACTIVITY" "replace" \
    "$SETUPWIZARD_ACTIVITY_METHOD" \
    "navigationbar_setting" \
    "this_string_does_not_exist" \
    > /dev/null
unset NAV_STEP_FILE NAV_STEP_METHOD SETUPWIZARD_ACTIVITY SETUPWIZARD_ACTIVITY_METHOD

LOG "- Disabling Recommended apps step"
EVAL "sed -i \"/omcagent/d\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/res/values/arrays.xml\""

# Dynamically patch SecSetupWizard_Global
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSetupWizard_Global.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSetupWizard_Global.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSetupWizard_Global.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSetupWizard_Global.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSetupWizard_Global.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSetupWizard_Global.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSetupWizard_Global.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\\\\\\\\"/\\\\\\\\\\\\\\\\\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk/$f\""
    fi
done < <(find "$MODPATH/SecSetupWizard_Global.apk" -type f)

if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "36" ]; then
    LOG "- Porting custom disclaimer page to Android 16"
    SETUPWIZARD_PUBLIC="$SETUPWIZARD_APK/res/values/public.xml"

    if ! grep -q 'name="suw_ic_unica"' "$SETUPWIZARD_PUBLIC"; then
        LAST_DRAWABLE_ID="$(grep '<public type="drawable"' "$SETUPWIZARD_PUBLIC" \
            | tail -n 1 | sed -n 's/.* id="\(0x[0-9a-fA-F]*\)".*/\1/p')"
        DISCLAIMER_ICON_ID="$(printf '0x%08x' "$((LAST_DRAWABLE_ID + 1))")"
        awk -v entry="    <public type=\"drawable\" name=\"suw_ic_unica\" id=\"$DISCLAIMER_ICON_ID\" />" '
            !inserted && /<public type="id"/ { print entry; inserted = 1 }
            { print }
        ' "$SETUPWIZARD_PUBLIC" > "$SETUPWIZARD_PUBLIC.tmp"
        EVAL "mv \"$SETUPWIZARD_PUBLIC.tmp\" \"$SETUPWIZARD_PUBLIC\""
    else
        DISCLAIMER_ICON_ID="$(sed -n 's/.*name="suw_ic_unica" id="\(0x[0-9a-fA-F]*\)".*/\1/p' "$SETUPWIZARD_PUBLIC")"
    fi

    if ! grep -q 'name="disclaimer_unica_description"' "$SETUPWIZARD_PUBLIC"; then
        LAST_STRING_ID="$(grep '<public type="string"' "$SETUPWIZARD_PUBLIC" \
            | tail -n 1 | sed -n 's/.* id="\(0x[0-9a-fA-F]*\)".*/\1/p')"
        DISCLAIMER_STRING_ID="$(printf '0x%08x' "$((LAST_STRING_ID + 1))")"
        awk -v entry="    <public type=\"string\" name=\"disclaimer_unica_description\" id=\"$DISCLAIMER_STRING_ID\" />" '
            !inserted && /<public type="style"/ { print entry; inserted = 1 }
            { print }
        ' "$SETUPWIZARD_PUBLIC" > "$SETUPWIZARD_PUBLIC.tmp"
        EVAL "mv \"$SETUPWIZARD_PUBLIC.tmp\" \"$SETUPWIZARD_PUBLIC\""
    else
        DISCLAIMER_STRING_ID="$(sed -n 's/.*name="disclaimer_unica_description" id="\(0x[0-9a-fA-F]*\)".*/\1/p' "$SETUPWIZARD_PUBLIC")"
    fi

    DISCLAIMER_STEP_FILE="$(find "$SETUPWIZARD_APK" -type f -name '*.smali' \
        -exec grep -lF '"disclaimer"' {} + | sed -n '1p')"
    [ "$DISCLAIMER_STEP_FILE" ] || ABORT "Disclaimer setup step implementation not found"
    DISCLAIMER_STEP_METHOD="$(awk '/^\.method/{method=$0} /"disclaimer"/{print method; exit}' \
        "$DISCLAIMER_STEP_FILE" | sed -E 's/^\.method ([^ ]+ )*//')"
    DISCLAIMER_STEP_FILE="${DISCLAIMER_STEP_FILE//$SETUPWIZARD_APK\//}"
    SMALI_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
        "$DISCLAIMER_STEP_FILE" "replace" "$DISCLAIMER_STEP_METHOD" \
        "disclaimer" "this_string_does_not_exist" > /dev/null

    DISCLAIMER_ACTIVITY="$SETUPWIZARD_APK/smali/com/sec/android/app/SecSetupWizard/UI/DisclaimerActivity.smali"
    DISCLAIMER_BASE_CLASS="$(sed -n 's/^\.super //p' "$DISCLAIMER_ACTIVITY" | sed -n '1p')"
    DISCLAIMER_BASE_SMALI="$SETUPWIZARD_APK/smali/${DISCLAIMER_BASE_CLASS#L}"
    DISCLAIMER_BASE_SMALI="${DISCLAIMER_BASE_SMALI%;}.smali"
    DISCLAIMER_ICON_METHOD="$(sed -n -E 's/^\.method .* ([^ ]+)\(Landroid\/graphics\/drawable\/Drawable;\)V$/\1/p' \
        "$DISCLAIMER_BASE_SMALI" | sed -n '1p')"
    [ "$DISCLAIMER_ICON_METHOD" ] || ABORT "Disclaimer icon setter implementation not found"

    awk -v icon_id="$DISCLAIMER_ICON_ID" -v string_id="$DISCLAIMER_STRING_ID" \
        -v base_class="$DISCLAIMER_BASE_CLASS" -v icon_method="$DISCLAIMER_ICON_METHOD" '
        /^\.method .* onCreate\(Landroid\/os\/Bundle;\)V$/ { in_on_create = 1 }
        in_on_create && !icon_added && /->setContentView\(I\)V$/ {
            print
            print ""
            print "    const p1, " icon_id
            print ""
            print "    invoke-virtual {p0, p1}, Landroid/content/Context;->getDrawable(I)Landroid/graphics/drawable/Drawable;"
            print ""
            print "    move-result-object p1"
            print ""
            print "    invoke-virtual {p0, p1}, " base_class "->" icon_method "(Landroid/graphics/drawable/Drawable;)V"
            icon_added = 1
            next
        }
        in_on_create && /check-cast p1, Landroid\/widget\/TextView;/ {
            print
            print ""
            print "    const v0, " string_id
            print ""
            print "    invoke-virtual {p0, v0}, Landroid/content/Context;->getString(I)Ljava/lang/String;"
            print ""
            print "    move-result-object p0"
            print ""
            print "    invoke-virtual {p1, p0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V"
            print ""
            print "    return-void"
            replace_tail = 1
            next
        }
        replace_tail && /^\.end method$/ {
            print
            replace_tail = 0
            in_on_create = 0
            next
        }
        replace_tail { next }
        { print }
    ' "$DISCLAIMER_ACTIVITY" > "$DISCLAIMER_ACTIVITY.tmp"
    EVAL "mv \"$DISCLAIMER_ACTIVITY.tmp\" \"$DISCLAIMER_ACTIVITY\""
else
    APPLY_PATCH "system" "system/priv-app/SecSetupWizard_Global/SecSetupWizard_Global.apk" \
        "$MODPATH/legacy/SecSetupWizard_Global.apk/0001-Add-custom-disclaimer-page.patch"
fi

unset PATCH_INST CONTENT SETUPWIZARD_PUBLIC LAST_DRAWABLE_ID LAST_STRING_ID \
    DISCLAIMER_ICON_ID DISCLAIMER_STRING_ID DISCLAIMER_STEP_FILE DISCLAIMER_STEP_METHOD \
    DISCLAIMER_ACTIVITY DISCLAIMER_BASE_CLASS DISCLAIMER_BASE_SMALI DISCLAIMER_ICON_METHOD
