#!/bin/bash
# =============================================
#   Nexus OS — Navbar Overlay Builder
#   Lance ce script sur ta VM Genymotion (Linux)
#   avec : bash BUILD.sh
# =============================================

echo "=== Nexus OS Navbar Overlay Builder ==="

# Vérifier aapt2
if ! command -v aapt2 &>/dev/null; then
    echo "[!] aapt2 non trouvé. Installation..."
    # Sur Ubuntu/Debian :
    sudo apt-get install -y aapt 2>/dev/null || \
    # Ou via Android SDK Build Tools
    echo "[!] Installe Android SDK Build Tools et réessaie."
    exit 1
fi

OUTDIR="./out"
mkdir -p "$OUTDIR/compiled"

echo "[1] Compilation des ressources..."
aapt2 compile \
    res/drawable/ic_sysbar_home.xml \
    res/drawable/ic_sysbar_back.xml \
    res/drawable/ic_sysbar_recent_apps.xml \
    -o "$OUTDIR/compiled/"

echo "[2] Link de l'APK..."
aapt2 link \
    --manifest AndroidManifest.xml \
    -o "$OUTDIR/NexusNavbar.apk" \
    --auto-add-overlay \
    -R "$OUTDIR/compiled/"*.flat \
    -I "$ANDROID_HOME/platforms/android-33/android.jar" 2>/dev/null || \
aapt2 link \
    --manifest AndroidManifest.xml \
    -o "$OUTDIR/NexusNavbar.apk" \
    --auto-add-overlay \
    -R "$OUTDIR/compiled/"*.flat \
    -I "$(find /usr -name 'android.jar' 2>/dev/null | head -1)"

echo "[3] Signature de l'APK..."
if command -v apksigner &>/dev/null; then
    apksigner sign \
        --ks ~/.android/debug.keystore \
        --ks-pass pass:android \
        "$OUTDIR/NexusNavbar.apk"
else
    # Signature avec jarsigner (fallback)
    keytool -genkey -v \
        -keystore nexus.keystore \
        -alias nexusos \
        -keyalg RSA -keysize 2048 \
        -validity 10000 \
        -storepass nexusos \
        -keypass nexusos \
        -dname "CN=NexusOS" 2>/dev/null
    jarsigner -verbose \
        -keystore nexus.keystore \
        -storepass nexusos \
        -keypass nexusos \
        "$OUTDIR/NexusNavbar.apk" nexusos
fi

echo ""
echo "=== APK généré : $OUTDIR/NexusNavbar.apk ==="
echo "=> Copier dans : system/overlay/NexusNavbar.apk"
