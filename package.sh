#!/bin/bash

set -euo pipefail

pwd=$(pwd)
echo '当前目录：'
echo $pwd

echo '编译插件'
xmake

echo '编译Go服务器'
cd $pwd/go_server
./build.sh
cd $pwd
echo '----------------'

# 临时文件
mkdir weibo_plugin
cp go_server/server ./weibo_plugin
cp build/linux/arm64-v8a/release/libweibo_plugin.so ./weibo_plugin
cp -r ./qml ./weibo_plugin
cp metadata.json ./weibo_plugin
cp icon.png ./weibo_plugin

# 打包
zip -r weibo_plugin.zip weibo_plugin/*

# 清除
rm -r ./weibo_plugin

echo '----------------'
echo '打包完成'
