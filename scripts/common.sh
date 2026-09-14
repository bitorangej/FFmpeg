#!/usr/bin/env bash
# 由 configure.sh / build.sh / bear-build.sh 共同引入，不单独执行。
# 作用：解析构建类型，给出 BUILD_TYPE 与 BUILD_DIR 两个变量。
# FFmpeg 支持源外构建，因此 debug 与 release 各占一个目录，互不干扰。

# 解析第一个位置参数为构建类型，缺省 release
resolve_build_type() {
    BUILD_TYPE="${1:-release}"
    case "$BUILD_TYPE" in
    debug | release) ;;
    *)
        echo "未知构建类型: $BUILD_TYPE" >&2
        echo "用法: $(basename "$0") [debug|release] [额外参数...]" >&2
        exit 1
        ;;
    esac
    BUILD_DIR="build-$BUILD_TYPE"
}

# 默认并发数。裸 make -j 是无上限并发（不是"跑满所有核心"），FFmpeg 有数千个编译单元，
# 会瞬间拉起上千个 cc 进程把内存打满。nproc 尊重 cgroup 配额与 CPU 亲和性掩码，容器里同样正确。
# 调用方把结果放在 "$@" 之前，因此 scripts/build.sh debug -j8 仍可覆盖（make 取最后一个 -j）。
default_jobs() {
    nproc 2>/dev/null || echo 4
}

# 确认目标目录已经 configure 过，否则给出明确提示
require_configured() {
    if [ ! -f "$BUILD_DIR/ffbuild/config.mak" ]; then
        echo "$BUILD_DIR 尚未配置，先执行: scripts/configure.sh $BUILD_TYPE" >&2
        exit 1
    fi
}
