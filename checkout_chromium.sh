#!/usr/bin/env bash

# usage:
# $0
# $0 [revision]

# get android revision
# curl 'https://chromereleases.googleblog.com/search/label/Chrome%20for%20Android' | grep -o 'just released Chrome .*for Android'

OS=`uname -s`
HostOS=Linux
case "$OS" in
  Linux)    HostOS=Linux ;;
  Darwin)   HostOS=Darwin ;;
  CYGWIN*)  HostOS=CYGWIN;  echo "Unsupported OS ${OS}"; exit 1;;
  MINGW*)   HostOS=MINGW;   echo "Unsupported OS ${OS}"; exit 1;;
  *)        HostOS=Unknown; echo "Unsupported OS ${OS}"; exit 1;;
esac

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
die() { echo "$*"; exit 1; }

sed_inplace_opt=("-i")
if [[ $HostOS == Darwin ]] && ! sed --version &>/dev/null; then
  sed_inplace_opt=("-i" "")
fi


revision="${1:-master}"


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
else
  if run git --git-dir="$chromium_src_dir/.git" fetch origin "$revision" >/dev/null; then
    run git --git-dir="$chromium_src_dir/.git" --work-tree="$chromium_src_dir" checkout -f FETCH_HEAD || exit 1
  else
    run git --git-dir="$chromium_src_dir/.git" fetch origin || exit 1
    run git --git-dir="$chromium_src_dir/.git" --work-tree="$chromium_src_dir" checkout -f "$revision" || exit 1
  fi

fi

sed "${sed_inplace_opt[@]}" -e "/^target_os/d" "$chromium_root_dir/.gclient"
echo 'target_os = ["android", "linux"]' >>  "$chromium_root_dir/.gclient"

run gclient sync --with_branch_heads --with_tags --force --reset -D --nohooks || exit 1
run gclient runhooks || exit 1

exit 0

