#!/usr/bin/env bash
set -euo pipefail

# 用法: scripts/build.sh [debug|release] [透传给 make 的额外参数...]
# 缺省 release。

# 始终以源码树根（脚本目录的上一级）为基准，避免从别处调用时路径错乱
cd "$(dirname "$0")/.."
source scripts/common.sh

resolve_build_type "${1:-}"
if [ $# -gt 0 ]; then shift; fi
require_configured

cd "$BUILD_DIR"

# 不执行 make clean：FFmpeg 用 -MMD 逐文件生成 .d 依赖，并由 ffbuild/common.mak 引入，
# 头文件依赖被完整追踪，增量编译可靠。需要全量重建时改跑 scripts/configure.sh
make "-j$(default_jobs)" "$@"
