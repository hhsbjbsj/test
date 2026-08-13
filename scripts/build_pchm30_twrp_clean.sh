#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$PWD}/_twrp_clean"
SRC="$ROOT/src"
OUTROOT="${GITHUB_WORKSPACE:-$PWD}/artifacts"
LOG="$OUTROOT/build.log"

GINKGO_REPO="https://github.com/TeamWin/android_device_xiaomi_ginkgo.git"
GINKGO_COMMIT="362c5581fb5555a81d4c7e957bf4c71fa15df5d0"
GINKGO_TIME_UTC="2025-06-07T08:08:19Z"
PCHM30_REPO="https://github.com/wowk60392/android_device_oppo_PCHM30.git"
PCHM30_COMMIT="c6e42d76ec242ebd77627adc998b9f3dc94a3e1e"
TWRP_MANIFEST="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git"
TWRP_BRANCH="twrp-12.1"

mkdir -p "$ROOT" "$OUTROOT"
rm -rf "$SRC"
mkdir -p "$SRC"
cd "$SRC"

echo "===== INIT CLEAN TWRP 12.1 ====="
repo init --depth=1 -u "$TWRP_MANIFEST" -b "$TWRP_BRANCH"
repo sync -c -j2 --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

echo "===== PIN DEVICE TREES ====="
rm -rf device/oppo/PCHM30 device/xiaomi/ginkgo-reference device/qcom/common device/qcom/twrp-common

git clone --filter=blob:none --no-checkout "$PCHM30_REPO" device/oppo/PCHM30
git -C device/oppo/PCHM30 fetch --depth=1 origin "$PCHM30_COMMIT"
git -C device/oppo/PCHM30 checkout --detach FETCH_HEAD

git clone --filter=blob:none --no-checkout "$GINKGO_REPO" device/xiaomi/ginkgo-reference
git -C device/xiaomi/ginkgo-reference fetch --depth=1 origin "$GINKGO_COMMIT"
git -C device/xiaomi/ginkgo-reference checkout --detach FETCH_HEAD

git clone --depth=1 -b android-12.1 https://github.com/TeamWin/android_device_qcom_common.git device/qcom/common
git clone --depth=1 -b android-12.1 https://github.com/TeamWin/android_device_qcom_twrp-common.git device/qcom/twrp-common

P="device/oppo/PCHM30"
G="device/xiaomi/ginkgo-reference"

# Verify the known PCHM30 recovery kernel and dtbo blobs before using them.
[[ "$(git hash-object "$P/prebuilt/Image.gz-dtb")" == "06deab936122357025ec306203d1b7b546ad4149" ]]
[[ "$(git hash-object "$P/prebuilt/dtbo.img")" == "397c9c168db933f71e9884e28e98944d7223f751" ]]

# Convert the old generated Omni tree into a clean native TWRP 12.1 product.
rm -f "$P/omni_PCHM30.mk" "$P/vendorsetup.sh"
cat > "$P/AndroidProducts.mk" <<'EOF'
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_PCHM30.mk

COMMON_LUNCH_CHOICES := \
    twrp_PCHM30-eng
EOF

cat > "$P/twrp_PCHM30.mk" <<'EOF'
PRODUCT_RELEASE_NAME := PCHM30

$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/oppo/PCHM30/device.mk)

PRODUCT_DEVICE := PCHM30
PRODUCT_NAME := twrp_PCHM30
PRODUCT_BRAND := OPPO
PRODUCT_MODEL := OPPO A11x
PRODUCT_MANUFACTURER := OPPO
EOF

cat > "$P/device.mk" <<'EOF'
LOCAL_PATH := device/oppo/PCHM30

PRODUCT_SHIPPING_API_LEVEL := 28

# TeamWin Qualcomm recovery decryption modules used by the latest ginkgo tree.
PRODUCT_PACKAGES_ENG += \
    qcom_decrypt \
    qcom_decrypt_fbe

PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# PCHM30 is static A-only; do not import ginkgo dynamic/super geometry.
PRODUCT_USE_DYNAMIC_PARTITIONS := false
EOF

cat > "$P/BoardConfig.mk" <<'EOF'
DEVICE_PATH := device/oppo/PCHM30

ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a73
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a73
TARGET_USES_64_BIT_BINDER := true

TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME := trinket
TARGET_BOARD_PLATFORM := trinket
TARGET_OTA_ASSERT_DEVICE := PCHM30

BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=1 firmware_class.path=/vendor/firmware_mnt/image earlycon=msm_geni_serial,0x4a90000 loop.max_part=7 cgroup.memory=nokmem,nosocket buildvariant=user
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_BOOTIMG_HEADER_VERSION := 1
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_AVB_ENABLE := false

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_COPY_OUT_VENDOR := vendor
BOARD_USES_METADATA_PARTITION := true

TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
RECOVERY_SDCARD_ON_DATA := true
TW_THEME := portrait_hdpi
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1600
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_REPACKTOOLS := true
TW_NO_SCREEN_TIMEOUT := true
TW_INPUT_BLACKLIST := hbtp_vm

# Latest official ginkgo (TeamWin android-12.1, 2025-06-07) crypto model.
TW_INCLUDE_FBE_METADATA_DECRYPT := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE := true
TW_USE_FSCRYPT_POLICY := 2
TW_FORCE_KEYMASTER_VER := true
TW_PREPARE_DATA_MEDIA_EARLY := true
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PRODUCT_ENFORCE_VINTF_MANIFEST := true

TARGET_RECOVERY_DEVICE_MODULES += \
    libion \
    libxml2
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/libion.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libxml2.so

TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
EOF

cat > "$P/system.prop" <<'EOF'
vendor.gatekeeper.disable_spu=true
keymaster_ver=4.0
ro.crypto.dm_default_key.options_format.version=2
ro.crypto.volume.metadata.method=dm-default-key
ro.crypto.volume.filenames_mode=aes-256-cts
ro.crypto.volume.options=::v2
EOF

# PCHM30-specific static ext4 fstab. Do not copy ginkgo's f2fs userdata entry.
cat > "$P/recovery.fstab" <<'EOF'
/system       ext4 /dev/block/bootdevice/by-name/system   flags=display="System";backup=1
/vendor       ext4 /dev/block/bootdevice/by-name/vendor   flags=display="Vendor";backup=1
/cache        ext4 /dev/block/bootdevice/by-name/cache    flags=display="Cache"
/metadata     ext4 /dev/block/bootdevice/by-name/metadata flags=display="Metadata"
/data         ext4 /dev/block/bootdevice/by-name/userdata flags=display="Data";storage;wipeingui;fileencryption=ice;wrappedkey;keydirectory=/metadata/vold/metadata_encryption
/boot         emmc /dev/block/bootdevice/by-name/boot     flags=display="Boot";backup=1;flashimg=1
/recovery     emmc /dev/block/bootdevice/by-name/recovery flags=display="Recovery";backup=1;flashimg=1
/dtbo         emmc /dev/block/bootdevice/by-name/dtbo     flags=display="DTBO";backup=1;flashimg=1
/misc         emmc /dev/block/bootdevice/by-name/misc     flags=display="Misc"
/persist      ext4 /dev/block/bootdevice/by-name/persist  flags=display="Persist"
/modem        emmc /dev/block/bootdevice/by-name/modem    flags=display="Modem";backup=1
/external_sd  auto /dev/block/mmcblk1p1                    flags=display="MicroSD";storage;wipeingui;removable
/usb_otg      auto /dev/block/sdd1 /dev/block/sdd         flags=display="USB-Storage";storage;wipeingui;removable
EOF

# Keep PCHM30's own recovery init, but import TeamWin's Qualcomm decryption service layer.
python3 - "$P/recovery/root/init.recovery.qcom.rc" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
s = p.read_text()
imp = 'import /init.recovery.qcom_decrypt.rc'
if imp not in s:
    s = imp + '\n\n' + s
if 'setprop prepdecrypt.loglevel 2' not in s:
    marker = 'on init\n'
    if marker in s:
        s = s.replace(marker, marker + '    setprop prepdecrypt.loglevel 2\n', 1)
    else:
        s += '\n\non init\n    setprop prepdecrypt.loglevel 2\n'
p.write_text(s)
PY

# Import only the modern ginkgo QCOM decrypt prebuilts, not its boot geometry/fstab/display config.
mkdir -p "$P/recovery/root/system/bin" "$P/recovery/root/vendor/lib64/hw" "$P/recovery/root/vendor/etc/vintf/manifest"
for f in \
    qseecomd \
    android.hardware.keymaster@4.0-service-qti \
    android.hardware.gatekeeper@1.0-service-qti; do
    cp -f "$G/recovery/root/system/bin/$f" "$P/recovery/root/system/bin/$f"
done
for f in \
    libQSEEComAPI.so \
    libdrmfs.so \
    libqtikeymaster4.so \
    libkeymasterdeviceutils.so \
    libkeymasterutils.so \
    libqcbor.so \
    libdiag.so; do
    cp -f "$G/recovery/root/vendor/lib64/$f" "$P/recovery/root/vendor/lib64/$f"
done
cp -f "$G/recovery/root/vendor/lib64/hw/android.hardware.gatekeeper@1.0-impl-qti.so" \
      "$P/recovery/root/vendor/lib64/hw/android.hardware.gatekeeper@1.0-impl-qti.so"

cat > "$P/recovery/root/vendor/etc/vintf/manifest/pchm30-decrypt.xml" <<'EOF'
<manifest version="1.0" type="device">
    <hal format="hidl">
        <name>android.hardware.gatekeeper</name>
        <transport>hwbinder</transport>
        <version>1.0</version>
        <interface><name>IGatekeeper</name><instance>default</instance></interface>
        <fqname>@1.0::IGatekeeper/default</fqname>
    </hal>
    <hal format="hidl">
        <name>android.hardware.keymaster</name>
        <transport>hwbinder</transport>
        <version>4.0</version>
        <interface><name>IKeymasterDevice</name><instance>default</instance></interface>
        <fqname>@4.0::IKeymasterDevice/default</fqname>
    </hal>
</manifest>
EOF

cat > "$OUTROOT/BUILD_PROVENANCE.txt" <<EOF
Target: OPPO A11x / PCHM30
Build: clean native TeamWin TWRP 12.1
TWRP manifest: $TWRP_MANIFEST ($TWRP_BRANCH)
Official ginkgo device tree: $GINKGO_REPO
Official ginkgo pinned commit: $GINKGO_COMMIT
Official ginkgo commit time UTC: $GINKGO_TIME_UTC
Official ginkgo commit time China: 2025-06-07T16:08:19+08:00
PCHM30 hardware-shell tree: $PCHM30_REPO
PCHM30 pinned commit: $PCHM30_COMMIT
Kernel Git blob: 06deab936122357025ec306203d1b7b546ad4149
DTBO Git blob: 397c9c168db933f71e9884e28e98944d7223f751
EOF

export ALLOW_MISSING_DEPENDENCIES=true
export USE_CCACHE=1
export CCACHE_EXEC="$(command -v ccache || true)"
export CCACHE_DIR="${CCACHE_DIR:-$ROOT/ccache}"
ccache -M 8G || true

set +u
source build/envsetup.sh
lunch twrp_PCHM30-eng
set -u

echo "===== BUILD NATIVE TWRP RECOVERY ====="
set +e
if declare -F mka >/dev/null 2>&1; then
    mka -j2 recoveryimage 2>&1 | tee "$LOG"
    RC=${PIPESTATUS[0]}
else
    m -j2 recoveryimage 2>&1 | tee "$LOG"
    RC=${PIPESTATUS[0]}
fi
set -e

[[ $RC -eq 0 ]] || exit "$RC"

IMG="$SRC/out/target/product/PCHM30/recovery.img"
[[ -f "$IMG" ]]
cp -f "$IMG" "$OUTROOT/PCHM30-TWRP-12.1-CLEAN-GINKGO-20250607.img"
sha256sum "$OUTROOT/PCHM30-TWRP-12.1-CLEAN-GINKGO-20250607.img" > "$OUTROOT/SHA256SUMS.txt"
stat -c 'size=%s bytes' "$OUTROOT/PCHM30-TWRP-12.1-CLEAN-GINKGO-20250607.img" >> "$OUTROOT/BUILD_PROVENANCE.txt"

# Basic final payload checks; fail CI rather than publish an incomplete decrypt build.
R="$SRC/out/target/product/PCHM30/recovery/root"
for f in \
    init.recovery.qcom_decrypt.rc \
    init.recovery.qcom_decrypt.fbe.rc \
    system/bin/prepdecrypt.sh \
    system/bin/qseecomd \
    system/bin/android.hardware.keymaster@4.0-service-qti \
    system/bin/android.hardware.gatekeeper@1.0-service-qti \
    system/lib64/libfscrypttwrp.so; do
    [[ -e "$R/$f" ]] || { echo "MISSING FINAL PAYLOAD: $f"; exit 90; }
done

[[ "$(stat -c %s "$IMG")" -le 67108864 ]] || { echo 'recovery image exceeds 64MiB'; exit 91; }

echo "BUILD PASS"
cat "$OUTROOT/SHA256SUMS.txt"
