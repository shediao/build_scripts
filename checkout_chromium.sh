#!/usr/bin/env bash

script_dir="$(cd "$(dirname "$0")" && pwd)"

depot_tools_repo="https://chromium.googlesource.com/chromium/tools/depot_tools.git"

chromium_root_dir="$script_dir/chromium"
depot_tools_dir="$chromium_root_dir/depot_tools"
chromium_src_dir="$chromium_root_dir/src"

# for depot_tools
export NO_AUTH_BOTO_CONFIG=/dev/null
export DEPOT_TOOLS_METRICS=0
export DEPOT_TOOLS_UPDATE=0

run() { echo "$* (in ${PWD})"; "$@"; }

if [[ ! -d "$chromium_root_dir" ]]; then
  run mkdir "$chromium_root_dir" || exit 1
fi

cd $chromium_root_dir || exit 1

if [[ ! -d "$depot_tools_dir" ]]; then
  run git clone "$depot_tools_repo" "$depot_tools_dir"
else
  run git --git-dir="$depot_tools_dir/.git" fetch origin || exit 1
  run git --git-dir="$depot_tools_dir/.git" --work-tree="$depot_tools_dir" checkout -f origin/master || exit 1
fi

export PATH="$depot_tools_dir:$PATH"

which gclient || exit 1


if [[ ! -f "$chromium_root_dir/.gclient" ]]; then
  run fetch --nohooks android || exit 1
  # src/build/install-build-deps-android.sh
fi

run gclient sync --with_branch_heads --with_tags --force --reset --nohooks || exit 1
run gclient runhooks || exit 1

exit 0

