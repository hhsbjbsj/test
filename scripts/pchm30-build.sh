#!/usr/bin/env bash
set -euo pipefail

LINEAGE_BRANCH="${LINEAGE_BRANCH:-lineage-23.2}"
WORKDIR="${WORKDIR:-/work/lineage}"
PCHM30_PREBUILT_COMMIT="c6e42d76ec242ebd77627adc998b9f3dc94a3e1e"
PCHM30_KERNEL_BLOB="06deab936122357025ec306203d1b7b546ad4149"
PCHM30_DTBO_BLOB="397c9c168db933f71e9884e28e98944d7223f751"

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

git config --global user.name "${GITHUB_ACTOR:-PCHM30-CI}"
git config --global user.email "${GITHUB_ACTOR:-pchm30-ci}@users.noreply.github.com"

if [[ ! -d .repo ]]; then
  echo "::group::repo init (${LINEAGE_BRANCH})"
  # Partial clone is preferred on GitHub-hosted runners because a modern Android
  # checkout is very large. Fall back to a normal shallow init if the remote or
  # repo version rejects the filter.
  if ! repo init \
      -u https://github.com/LineageOS/android.git \
      -b "${LINEAGE_BRANCH}" \
      --git-lfs \
      --depth=1 \
      --partial-clone \
      --clone-filter=blob:limit=10M \
      --no-clone-bundle; then
    rm -rf .repo
    repo init \
      -u https://github.com/LineageOS/android.git \
      -b "${LINEAGE_BRANCH}" \
      --git-lfs \
      --depth=1 \
      --no-clone-bundle
  fi
  echo "::endgroup::"
fi

echo "::group::repo sync"
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags --prune

echo "::endgroup::"

echo "::group::inject PCHM30 device tree"
rm -rf device/oppo/PCHM30
mkdir -p device/oppo
cp -a "${GITHUB_WORKSPACE}/device/oppo/PCHM30" device/oppo/PCHM30
mkdir -p device/oppo/PCHM30/prebuilt

curl -fL --retry 5 --retry-delay 2 \
  "https://raw.githubusercontent.com/wowk60392/android_device_oppo_PCHM30/${PCHM30_PREBUILT_COMMIT}/prebuilt/Image.gz-dtb" \
  -o device/oppo/PCHM30/prebuilt/Image.gz-dtb
curl -fL --retry 5 --retry-delay 2 \
  "https://raw.githubusercontent.com/wowk60392/android_device_oppo_PCHM30/${PCHM30_PREBUILT_COMMIT}/prebuilt/dtbo.img" \
  -o device/oppo/PCHM30/prebuilt/dtbo.img

[[ "$(git hash-object device/oppo/PCHM30/prebuilt/Image.gz-dtb)" == "${PCHM30_KERNEL_BLOB}" ]]
[[ "$(git hash-object device/oppo/PCHM30/prebuilt/dtbo.img)" == "${PCHM30_DTBO_BLOB}" ]]
ls -lh device/oppo/PCHM30/prebuilt/
echo "::endgroup::"

echo "::group::configure Lineage product"
# shellcheck disable=SC1091
source build/envsetup.sh
breakfast PCHM30

echo "TARGET_PRODUCT=${TARGET_PRODUCT:-unset}"
echo "TARGET_BUILD_VARIANT=${TARGET_BUILD_VARIANT:-unset}"
echo "TARGET_RELEASE=${TARGET_RELEASE:-unset}"
echo "::endgroup::"

echo "::group::Soong/Make product parse"
m -j"$(nproc)" nothing
echo "::endgroup::"

echo "::group::PCHM30 boot image compile probe"
m -j"$(nproc)" bootimage
ls -lh out/target/product/PCHM30/boot.img
echo "::endgroup::"

# A system image is the next integration gate. It is expected to expose missing
# partition geometry / proprietary-HAL integration cleanly. The workflow will
# never advertise this output as flashable until those gates are resolved.
echo "::group::PCHM30 system image integration probe"
m -j"$(nproc)" systemimage
echo "::endgroup::"

mkdir -p "${GITHUB_WORKSPACE}/artifacts"
cp -f out/target/product/PCHM30/boot.img "${GITHUB_WORKSPACE}/artifacts/PCHM30-Lineage23.2-BOOT-COMPILE-PROBE.img"
if [[ -f out/target/product/PCHM30/system.img ]]; then
  cp -f out/target/product/PCHM30/system.img "${GITHUB_WORKSPACE}/artifacts/PCHM30-Lineage23.2-SYSTEM-COMPILE-PROBE.img"
fi
sha256sum "${GITHUB_WORKSPACE}"/artifacts/* | tee "${GITHUB_WORKSPACE}/artifacts/SHA256SUMS.txt"
