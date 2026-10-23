#!/bin/bash
source common.sh
set_keys
export VERSION=$(grep -m1 -o '[0-9]\+\(\.[0-9]\+\)\{3\}' vanadium/args.gn)
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git # https://github.com/chromium/chromium.git
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick librsvg2-bin
sudo dpkg --add-architecture i386; sudo apt-get update; sudo apt-get install -y libgcc-s1:i386

if [ ! -d depot_tools ]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi
export PATH="$PWD/depot_tools:$PATH"
mkdir -p chromium/src/out/Default; cd chromium/src
if [ ! -d .git ]; then
  git init
fi
git remote set-url origin $CHROMIUM_SOURCE 2>/dev/null || git remote add origin $CHROMIUM_SOURCE
git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION
git checkout -f $VERSION
cp $SCRIPT_DIR/.gclient ../.gclient

# https://grapheneos.org/build#browser-and-webview
rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-{apk-build-targets,browser-apk-targets}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*{detailed,supported}-language*.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*javascript-optimizer-{site-setting,settings-UI}.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*{pdf,PDF,for-content-public,toolbar-button,configs-from-config-app,config-app-parsing,new-tab-card,predictive-back,disable-learn-more-link-in-incognito-new-tab}*.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*crashpad*.patch
replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "TITANIUM"
replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Titanium"
replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "titanium"
git config --global user.name 'github-actions[bot]'
git config --global user.email 'github-actions[bot]@users.noreply.github.com'
git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch

gclient sync -D --no-history --nohooks
gclient runhooks
./build/install-build-deps.sh --no-prompt

source $SCRIPT_DIR/patch.sh

# Синхронизация меток времени: устанавливаем дату коммита для исходников Chromium,
# чтобы они гарантированно были старее любых скомпилированных объектов в сохраненном out/Default
echo "Синхронизация меток времени исходников Chromium..."
COMMIT_TIME=$(git log -1 --format=%ct)
find . -name '.git' -prune -o -name 'out' -prune -o -type f -exec touch -d "@$COMMIT_TIME" {} +

cp $SCRIPT_DIR/args.gn out/Default/args.gn
gn gen out/Default # gn args out/Default; echo 'treat_warnings_as_errors = false' >> out/Default/args.gn
mkdir -p out/tmp out/release

# Если задана переменная BUILD_TIMEOUT (например, 330m), прерываем Siso мягко без ошибки скрипта
if [ -n "$BUILD_TIMEOUT" ]; then
  timeout -k 5m "$BUILD_TIMEOUT" autoninja -C out/Default chrome_public_apk || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ] || [ $EXIT_CODE -eq 137 ]; then
      echo "Время этапа вышло. Прогресс сборки Siso сохранен в out/Default для следующего этапа."
      exit 0
    fi
    exit $EXIT_CODE
  }
else
  autoninja -C out/Default chrome_public_apk
fi

APK_FILE=$(find out/Default/apks -name 'Chrome*.apk' 2>/dev/null | head -n 1)
if [ -n "$APK_FILE" ]; then
  mv "$APK_FILE" out/tmp/$VERSION-arm64-v8a.apk
  export PATH=$PWD/third_party/jdk/current/bin/:$PATH
  export ANDROID_HOME=$PWD/third_party/android_sdk/public
  sign_apk out/tmp/$VERSION-arm64-v8a.apk out/release/$VERSION-arm64-v8a.apk
  rm -rf $SCRIPT_DIR/keys
fi
