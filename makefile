.PHONY: help clean format runner get
.PHONY: gen-go gen-rust
.PHONY: android-release android-debug window-release linux-deb macos-release hap
.PHONY: android-env build-all

# ============================================================
# 帮助信息
# ============================================================
help:
		@chcp 65001 >nul
		@echo "============================================"
		@echo "        Flutter 项目构建脚本"
		@echo "============================================"
		@echo "  常用命令:"
		@echo "    make get          - 安装依赖"
		@echo "    make clean        - 清理项目"
		@echo "    make format       - 格式化代码"
		@echo "    make runner       - 运行 build_runner 监听"
		@echo ""
		@echo "  代码生成:"
		@echo "    make gen-go       - 生成 Go 绑定代码"
		@echo "    make gen-rust     - 生成 Rust Bridge 代码"
		@echo ""
		@echo "  构建发布:"
		@echo "    make android-release - 构建 Android Release"
		@echo "    make android-build   - 构建 Android Debug"
		@echo "    make window-release  - 构建 Windows EXE"
		@echo "    make linux-deb       - 构建 Linux DEB"
		@echo "    make macos-release   - 构建 macOS DMG"
		@echo "    make hap             - 构建 OpenHarmony HAP"
		@echo ""
		@echo "  其他:"
		@echo "    make android-env - 添加 Android Rust 目标"
		@echo "    make build-all   - 批量构建 (Windows/Android/HAP)"
		@echo "============================================"

# ============================================================
# 基础命令 - 依赖与代码管理
# ============================================================

get:
		@echo "Get pub packages."
		@make clean
		@flutter pub get --no-example

clean:
		@echo "Cleaning flutter project..."
		@flutter clean

format:
		@echo "Formatting the code"
		@dart format lib/

runner:
		@echo "build_runner..."
		@dart run build_runner watch

# ============================================================
# 代码生成
# ============================================================

gen-go:
		@echo "gen the code"
		@dart run bindgo:run --config bindgo.yaml
		@dart run ffigen --config webrtc_ffi_config.yaml
		@dart run ffigen --config webdav_ffi_config.yaml

gen-rust:
		@echo "gen rust bridge code"
		@flutter_rust_bridge_codegen generate

# ============================================================
# 构建发布 - 各平台打包
# ============================================================

android-release:
		@echo "Build Android platform..."
		@flutter build apk --target-platform android-arm,android-arm64,android-x64 --split-per-abi

android-build:
		@dart pub global activate fastforge
		@fastforge package --platform android --targets apk \
			--build-target-platform android-arm,android-arm64,android-x64 \
			--flutter-build-args=split-per-abi --skip-clean

window-release:
		@dart pub global activate fastforge
		@echo "Build Windows platform..."
		@fastforge package --platform windows --targets exe --skip-clean

linux-deb:
		@dart pub global activate fastforge
		@echo "Build Linux deb platform..."
		@fastforge package --platform linux --targets deb --skip-clean

macos-release:
		@dart pub global activate fastforge
		@fastforge package --platform macos --targets dmg --skip-clean

hap:
		@flutter build hap --release --target-platform ohos-arm64
# 		@dart pub global activate fastforge
# 		@fastforge package --platform ohos --targets hap --build-target-platform ohos-arm64 --skip-clean
# 		--release --aot --target-platform=android-arm64

# ============================================================
# 环境配置
# ============================================================

android-env:
		@rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

harmony-env:
		@rustup target add aarch64-unknown-linux-ohos armv7-unknown-linux-ohos x86_64-unknown-linux-ohos
# ============================================================
# 批量构建
# ============================================================

build-all:
		@make window-release
		@make android-build
		@make hap

analyzer:
	@echo "Starting code analysis..."
	@dart pub global activate dead_code_analyzer
	@dead_code_analyzer -p ./ -o ./reports --funcs -s html
