#!/bin/bash
QTWEBENGINE_CHROMIUM_FLAGS=--widevine-path="`pwd`/libwidevinecdm.so" ./build/LogiQuick $*
