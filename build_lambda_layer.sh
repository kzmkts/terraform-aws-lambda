#!/bin/bash

# 古いlayerフォルダがあれば削除
if [ -d layer ]; then
  rm -rf layer
fi

# pythonフォルダに依存ライブラリをインストールする必要がある
pip install -r requirements.txt -t layer/python

# 不要なフォルダを削除
find layer \( -name '__pycache__' -o -name '*.dist-info' \) -type d -print0 | xargs -0 rm -rf
rm -rf python/bin
