#!/usr/bin/env python3
"""Use ART's native package filter callback for the r8s biometric UI only."""
from pathlib import Path
import re
import sys

NAME = "R8sBiometricCompilerFilter"
DESCRIPTOR = f"Lcom/android/server/pm/{NAME};"
REGISTER = "->setAdjustCompilerFilterCallback("
ANCHOR = "    const-class p1, Lcom/android/server/art/ArtManagerLocal;"
METHOD = "initializeArtManagerLocal(Landroid/content/Context;Lcom/android/server/pm/PackageManagerService;)V"
INSERT = f'''    # Reuse ART's own boot/update/background compilation, without a boot daemon.
    new-instance v2, {DESCRIPTOR}
    invoke-direct {{v2}}, {DESCRIPTOR}-><init>()V
    invoke-virtual {{v0, v2, v2}}, Lcom/android/server/art/ArtManagerLocal;->setAdjustCompilerFilterCallback(Ljava/util/concurrent/Executor;Lcom/android/server/art/ArtManagerLocal$AdjustCompilerFilterCallback;)V

'''
CALLBACK = f'''.class public final {DESCRIPTOR}
.super Ljava/lang/Object;
.implements Ljava/util/concurrent/Executor;
.implements Lcom/android/server/art/ArtManagerLocal$AdjustCompilerFilterCallback;

.method public constructor <init>()V
    .locals 0
    invoke-direct {{p0}}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public execute(Ljava/lang/Runnable;)V
    .locals 0
    invoke-interface {{p1}}, Ljava/lang/Runnable;->run()V
    return-void
.end method

.method public onAdjustCompilerFilter(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 1
    const-string v0, "com.samsung.android.biometrics.app.setting"
    invoke-virtual {{v0, p1}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :keep_original

    # Never override explicit shell requests or inactive-package reclamation.
    const-string v0, "first-boot"
    invoke-virtual {{v0, p3}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :use_speed
    const-string v0, "boot-after-ota"
    invoke-virtual {{v0, p3}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :use_speed
    const-string v0, "boot-after-mainline-update"
    invoke-virtual {{v0, p3}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :use_speed
    const-string v0, "bg-dexopt"
    invoke-virtual {{v0, p3}}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :keep_original
    :use_speed
    const-string v0, "speed"
    return-object v0
    :keep_original
    return-object p2
.end method
'''


def patch(root: Path) -> None:
    files = list(root.glob("smali*/com/android/server/pm/DexOptHelper.smali"))
    if len(files) != 1:
        raise ValueError(f"Expected one DexOptHelper, found {len(files)}")
    source = files[0]
    text = source.read_text(encoding="utf-8")
    callback = source.with_name(NAME + ".smali")
    if DESCRIPTOR in text:
        if text.count(INSERT) != 1 or not callback.exists() or callback.read_text() != CALLBACK:
            raise ValueError("Partial or changed biometric compiler callback")
        return
    # Do not silently displace a future donor's own compiler-filter policy.
    for path in root.glob("smali*/**/*.smali"):
        if REGISTER in path.read_text(encoding="utf-8"):
            raise ValueError(f"Existing ART compiler-filter callback in {path}")
    if callback.exists():
        raise ValueError("Unexpected existing biometric callback class")
    method = re.search(r"(?ms)^\.method public static " + re.escape(METHOD) + r"\n.*?^\.end method", text)
    if not method or method[0].count(ANCHOR) != 1 or "    .locals 5" not in method[0]:
        raise ValueError("ART initialization layout changed")
    if "->setBatchDexoptStartCallback(" not in method[0]:
        raise ValueError("Missing expected native ART batch setup")
    changed = method[0].replace(ANCHOR, INSERT + ANCHOR, 1)
    source.write_text(text[:method.start()] + changed + text[method.end():], encoding="utf-8", newline="\n")
    callback.write_text(CALLBACK, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    patch(Path(sys.argv[1]))
    print("Biometric UI uses speed in native ART boot/update/background dexopt")
