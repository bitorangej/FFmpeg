#!/usr/bin/env bash
set -euo pipefail

# 用法: scripts/configure.sh [debug|release] [透传给 configure 的额外参数...]
# 缺省 release。debug 与 release 分别配置到 build-debug/ 与 build-release/。

# 始终以源码树根（脚本目录的上一级）为基准，避免从别处调用时路径错乱
cd "$(dirname "$0")/.."
source scripts/common.sh

resolve_build_type "${1:-}"
if [ $# -gt 0 ]; then shift; fi

# 两种构建类型共用的外部库与许可开关
common_flags=(
    --enable-gpl
    --enable-nonfree
    --enable-version3
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libdav1d
    --enable-libsvtav1
    --enable-libfdk-aac
    --enable-libopus
    --enable-libmp3lame
    --enable-libass
    --enable-libfreetype
    --enable-libfontconfig
    --enable-libharfbuzz
    --enable-libfribidi
    --enable-libzimg
    --enable-openssl
)

# FFmpeg 的 configure 没有 build type 概念，debug/optimizations/stripping 是彼此正交的开关，
# 且三者默认全开（configure 中的 enable debug / enable optimizations / enable stripping），
# 即默认构建等价于 RelWithDebInfo + 安装时剥离符号，实际 CFLAGS 为 -g -O3 -fomit-frame-pointer。
case "$BUILD_TYPE" in
release)
    # 默认值即所需，无需追加任何开关
    type_flags=()
    ;;
debug)
    type_flags=(
        # 不追加任何 -O（cflags_noopt 为空），退回编译器默认 -O0；
        # 同时 configure 不再探测 -fomit-frame-pointer，栈回溯保持完整
        --disable-optimizations
        # ffmpeg 与 ffmpeg_g 都保留符号，省去只能调 _g 后缀的心智负担
        --disable-stripping
        # -g3，保留宏定义，便于在 gdb 里展开 FFmpeg 大量的宏
        --enable-debug=3
        # 打开 av_assert1 / av_assert2，运行明显变慢，但能抓住内部不变量违规
        --assert-level=2
    )
    ;;
esac

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

../configure "${common_flags[@]}" "${type_flags[@]}" "$@"
