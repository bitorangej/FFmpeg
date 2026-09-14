#!/usr/bin/env bash
set -euo pipefail

# 用法: scripts/bear-build.sh [debug|release] [透传给 make 的额外参数...]
# 缺省 release。全量重建并生成 compile_commands.json 供 clangd 使用。

# 始终以源码树根（脚本目录的上一级）为基准，避免从别处调用时路径错乱
cd "$(dirname "$0")/.."
source scripts/common.sh

resolve_build_type "${1:-}"
if [ $# -gt 0 ]; then shift; fi
require_configured

cd "$BUILD_DIR"

# bear 靠拦截编译进程来采集命令，必须全量重建才能覆盖所有文件
make clean

bear -- make "-j$(default_jobs)" "$@"

# 生成的 compile_commands.json 留在本构建目录内，由源码树根的 .clangd 指定使用哪一个
