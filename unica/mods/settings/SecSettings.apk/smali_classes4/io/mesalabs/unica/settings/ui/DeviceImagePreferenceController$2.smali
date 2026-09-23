.class public final synthetic Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$2;
.super Ljava/lang/Object;
.source "DeviceImagePreferenceController.java"

# interfaces
.implements Landroid/content/DialogInterface$OnClickListener;


# instance fields
.field public final synthetic val$context:Landroid/content/Context;


# direct methods
.method public synthetic constructor <init>(Landroid/content/Context;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$2;->val$context:Landroid/content/Context;

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/content/DialogInterface;I)V
    .locals 2

    const-string v0, "persist.sys.unica.device_image"

    const-string v1, ""

    invoke-static {v0, v1}, Landroid/os/SemSystemProperties;->set(Ljava/lang/String;Ljava/lang/String;)V

    invoke-interface {p1}, Landroid/content/DialogInterface;->dismiss()V

    iget-object p1, p0, Lio/mesalabs/unica/settings/ui/DeviceImagePreferenceController$2;->val$context:Landroid/content/Context;

    invoke-static {p1}, Lcom/samsung/android/settings/deviceinfo/aboutphone/DeviceImageFileUtils;->getImageFilePath(Landroid/content/Context;)Ljava/lang/String;

    move-result-object p1

    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p1}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v0}, Ljava/io/File;->delete()Z

    return-void
.end method