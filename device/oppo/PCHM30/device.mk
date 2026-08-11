# SPDX-License-Identifier: Apache-2.0

LOCAL_PATH := device/oppo/PCHM30

# PCHM30 is a static-partition, non-A/B device.
PRODUCT_USE_DYNAMIC_PARTITIONS := false
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# Minimal first-stage fstab for the initial compile/boot-image probe.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.qcom

# Keep the first probe intentionally small. Hardware packages, proprietary HALs,
# firmware and SELinux policy are added only after the base product parses and
# the correct PCHM30 proprietary-vendor source has been established.
