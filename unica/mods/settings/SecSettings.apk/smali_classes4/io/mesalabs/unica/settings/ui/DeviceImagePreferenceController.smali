.class public Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController;
.super Lcom/android/settings/core/BasePreferenceController;
.source "DeviceImagePreferenceController.java"


# direct methods
.method public constructor <init>(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0

    invoke-direct {p0, p1, p2}, Lcom/android/settings/core/BasePreferenceController;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    return-void
.end method


# virtual methods
.method public getAvailabilityStatus()I
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public getSummary()Ljava/lang/CharSequence;
    .locals 1

    const-string/jumbo p0, "persist.sys.unica.device_image"

    invoke-static {p0}, Landroid/os/SemSystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    invoke-static {p0}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string/jumbo p0, "ril.product_code"

    invoke-static {p0}, Landroid/os/SemSystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    :cond_0
    return-object p0
.end method

.method public handlePreferenceTreeClick(Landroidx/preference/Preference;)Z
    .locals 4

    invoke-virtual {p1}, Landroidx/preference/Preference;->getKey()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0}, Lcom/android/settings/core/BasePreferenceController;->getPreferenceKey()Ljava/lang/String;

    move-result-object v0

    invoke-static {p1, v0}, Landroid/text/TextUtils;->equals(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Z

    move-result p1

    if-eqz p1, :cond_0

    iget-object v0, p0, Lcom/android/settingslib/core/AbstractPreferenceController;->mContext:Landroid/content/Context;

    new-instance v1, Landroidx/appcompat/app/AlertDialog$Builder;

    invoke-direct {v1, v0}, Landroidx/appcompat/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V

    const-string v2, "string"

    const-string v3, "unica_device_image_dialog_title"

    invoke-static {v2, v3}, Lio/mesalabs/unica/utils/Utils;->getResourceId(Ljava/lang/String;Ljava/lang/String;)I

    move-result v2

    invoke-virtual {v1, v2}, Landroidx/appcompat/app/AlertDialog$Builder;->setTitle(I)V

    const-string v2, "string"

    const-string v3, "unica_device_image_dialog_msg"

    invoke-static {v2, v3}, Lio/mesalabs/unica/utils/Utils;->getResourceId(Ljava/lang/String;Ljava/lang/String;)I

    move-result v2

    invoke-virtual {v1, v2}, Landroidx/appcompat/app/AlertDialog$Builder;->setMessage(I)V

    new-instance v2, Landroid/widget/EditText;

    invoke-direct {v2, v0}, Landroid/widget/EditText;-><init>(Landroid/content/Context;)V

    const-string/jumbo v3, "persist.sys.unica.device_image"

    invoke-static {v3}, Landroid/os/SemSystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    invoke-static {v3}, Landroid/text/TextUtils;->isEmpty(Ljava/lang/CharSequence;)Z

    move-result p1

    if-eqz p1, :cond_1

    const-string/jumbo v3, "ril.product_code"

    invoke-static {v3}, Landroid/os/SemSystemProperties;->get(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    :cond_1
    invoke-virtual {v2, v3}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V

    invoke-virtual {v1, v2}, Landroidx/appcompat/app/AlertDialog$Builder;->setView(Landroid/view/View;)V

    const-string p1, "string"

    const-string v3, "unica_device_image_dialog_apply"

    invoke-static {p1, v3}, Lio/mesalabs/unica/utils/Utils;->getResourceId(Ljava/lang/String;Ljava/lang/String;)I

    move-result p1

    new-instance v3, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;

    invoke-direct {v3, v2, v0}, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;-><init>(Landroid/widget/EditText;Landroid/content/Context;)V

    invoke-virtual {v1, p1, v3}, Landroidx/appcompat/app/AlertDialog$Builder;->setPositiveButton(ILandroid/content/DialogInterface$OnClickListener;)V

    const-string p1, "string"

    const-string v3, "unica_device_image_dialog_reset"

    invoke-static {p1, v3}, Lio/mesalabs/unica/utils/Utils;->getResourceId(Ljava/lang/String;Ljava/lang/String;)I

    move-result p1

    new-instance v3, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$2;

    invoke-direct {v3, v0}, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$2;-><init>(Landroid/content/Context;)V

    invoke-virtual {v1, p1, v3}, Landroidx/appcompat/app/AlertDialog$Builder;->setNeutralButton(ILandroid/content/DialogInterface$OnClickListener;)V

    const-string p1, "string"

    const-string v3, "unica_device_image_dialog_cancel"

    invoke-static {p1, v3}, Lio/mesalabs/unica/utils/Utils;->getResourceId(Ljava/lang/String;Ljava/lang/String;)I

    move-result p1

    const/4 v3, 0x0

    invoke-virtual {v1, p1, v3}, Landroidx/appcompat/app/AlertDialog$Builder;->setNegativeButton(ILandroid/content/DialogInterface$OnClickListener;)V

    invoke-virtual {v1}, Landroidx/appcompat/app/AlertDialog$Builder;->create()Landroidx/appcompat/app/AlertDialog;

    move-result-object v0

    invoke-virtual {v0}, Landroid/app/Dialog;->show()V

    const/4 p0, 0x1

    return p0

    :cond_0
    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic getBackgroundWorkerClass()Ljava/lang/Class;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public getBackupKeys()Ljava/util/List;
    .locals 0

    new-instance p0, Ljava/util/ArrayList;

    invoke-direct {p0}, Ljava/util/ArrayList;-><init>()V

    return-object p0
.end method

.method public bridge synthetic getIntentFilter()Landroid/content/IntentFilter;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public bridge synthetic getLaunchIntent()Landroid/content/Intent;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public bridge synthetic getSliceHighlightMenuRes()I
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic getStatusText()Ljava/lang/String;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public bridge synthetic getValue()Lcom/samsung/android/settings/cube/ControlValue;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public bridge synthetic hasAsyncUpdate()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic ignoreUserInteraction()V
    .locals 0

    return-void
.end method

.method public bridge synthetic isControllable()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic isPublicSlice()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic isSliceable()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic needUserInteraction(Ljava/lang/Object;)Lcom/samsung/android/settings/cube/Controllable$ControllableType;
    .locals 0

    sget-object p0, Lcom/samsung/android/settings/cube/Controllable$ControllableType;->NO_INTERACTION:Lcom/samsung/android/settings/cube/Controllable$ControllableType;

    return-object p0
.end method

.method public bridge synthetic runDefaultAction()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public bridge synthetic setValue(Lcom/samsung/android/settings/cube/ControlValue;)Lcom/samsung/android/settings/cube/ControlResult;
    .locals 0

    const/4 p0, 0x0

    return-object p0
.end method

.method public bridge synthetic useDynamicSliceSummary()Z
    .locals 0

    const/4 p0, 0x0

    return p0
.end method