# PCHM30 LineageOS ROM Bring-up Lab

Experimental ROM bring-up workspace for OPPO A11x / PCHM30 (SM6125 / trinket).

This repository is intentionally isolated from the verified kernel and recovery branches. The first CI stage is a **compile probe**, not a flashable release: it validates the LineageOS product definition, boot image geometry and basic system build before any full OTA packaging is enabled.

Upstream references used for the initial seed:

- LineageOS `lineage-23.2` manifest
- LineageOS Xiaomi `ginkgo` / SM6125 trees as a modern trinket structural reference
- Public PCHM30 recovery tree for stock boot geometry and partition names
- `hhsbjbsj/android_kernel_oppo_sm6125-resukisu-final` remains untouched

## CI strategy

The workflow uses a shallow/current-branch LineageOS sync and maximises GitHub-hosted runner storage. It first builds `bootimage` and `systemimage`. A full `bacon`/OTA target is deliberately gated until the device tree and proprietary-vendor strategy are proven.

**Do not flash CI outputs until the workflow explicitly labels them flash-test-ready.**
