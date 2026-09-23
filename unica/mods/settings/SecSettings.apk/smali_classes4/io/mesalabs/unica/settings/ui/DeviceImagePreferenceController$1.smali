.class public final synthetic Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;
.super Ljava/lang/Object;
.source "DeviceImagePreferenceController.java"

# interfaces
.implements Landroid/content/DialogInterface$OnClickListener;


# instance fields
.field public final synthetic val$editText:Landroid/widget/EditText;

.field public final synthetic val$context:Landroid/content/Context;


# direct methods
.method public synthetic constructor <init>(Landroid/widget/EditText;Landroid/content/Context;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;->val$editText:Landroid/widget/EditText;

    iput-object p2, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;->val$context:Landroid/content/Context;

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/content/DialogInterface;I)V
    .locals 2

    iget-object v0, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;->val$editText:Landroid/widget/EditText;

    invoke-virtual {v0}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "persist.sys.unica.device_image"

    invoke-static {v1, v0}, Landroid/os/SemSystemProperties;->set(Ljava/lang/String;Ljava/lang/String;)V

    invoke-interface {p1}, Landroid/content/DialogInterface;->dismiss()V

    iget-object v0, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$1;->val$context:Landroid/content/Context;

    invoke-static {v0}, Lcom/samsung/android/settings/deviceinfo/aboutphone/DeviceImageFileUtils;->getImageFilePath(Landroid/content/Context;)Ljava/lang/String;

    move-result-object v0

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v0}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->delete()Z

    return-void
.end method