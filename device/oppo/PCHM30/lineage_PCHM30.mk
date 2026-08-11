# SPDX-License-Identifier: Apache-2.0

# 64-bit userspace with 32-bit app/HAL compatibility.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Common Lineage phone product.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# PCHM30 hardware definition.
$(call inherit-product, device/oppo/PCHM30/device.mk)

PRODUCT_NAME := lineage_PCHM30
PRODUCT_DEVICE := PCHM30
PRODUCT_MANUFACTURER := OPPO
PRODUCT_BRAND := OPPO
PRODUCT_MODEL := OPPO A11x

PRODUCT_GMS_CLIENTID_BASE := android-oppo
