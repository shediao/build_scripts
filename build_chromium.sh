#!/usr/bin/env bash

script_dir="$(cd "$(dirname "$0")" && pwd)"

chromium_root_dir="$script_dir/chromium"
depot_tools_dir="$chromium_root_dir/depot_tools"
chromium_src_dir="$chromium_root_dir/src"

export PATH="$depot_tools_dir:$PATH"

run() { echo "$* (in ${PWD})"; "$@"; }
die() { echo "$*"; exit 1; }

cd $chromium_src_dir || exit 1

out_dir="out/Default"

run gn gen $out_dir || exit 1

ninja -C "$out_dir" -t compdb cc cxx asm solink alink solink_module  > "$out_dir/compile_commands.json"

run ninja -C "$out_dir" chrome
