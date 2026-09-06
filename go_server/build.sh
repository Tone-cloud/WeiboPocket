#!/bin/bash

set -euo pipefail

echo '编译 Weibo API Server'
cd main
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o ../server
cd ..

echo '编译完成: server'
ls -lh server
