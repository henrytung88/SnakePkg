#!/bin/bash

ARCH_TARGET=${1:-X64}
BUILD_TARGET=${2:-DEBUG}
DEBUGGER=${3:-none} # none | gdb | lldb

case $ARCH_TARGET in
    X64|IA32) ;;
    *)
        echo "Error: Invalid architecture '$ARCH_TARGET'"
        exit 1
        ;;
esac

case $DEBUGGER in
    none|gdb|lldb) ;;
    *)
        echo "Error: Invalid debugger '$DEBUGGER'"
        exit 1
        ;;
esac

case $ARCH_TARGET in
    X64)
        BOOT_FILE="BOOTX64.EFI"
        QEMU_ARCH="x86_64"
        OVMF_ARCH="x64"
        ;;
    IA32)
        BOOT_FILE="BOOTIA32.EFI"
        QEMU_ARCH="i386"
        OVMF_ARCH="ia32"
        ;;
esac

if [[ "$DEBUGGER" != "none" ]]; then
    if [[ "$ARCH_TARGET" != "X64" ]]; then
        echo "Only X64 is supported for debugging support!"
        exit 1
    fi

    echo "Building OvmfPkg for $OVMF_ARCH DEBUG..."
    ./ovmf_build.sh $ARCH_TARGET $BUILD_TARGET || exit $?

    OVMF_CODE="../../Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd"
    OVMF_VARS="../../Build/OvmfX64/DEBUG_GCC5/FV/OVMF_VARS.fd"
    USE_SPLIT=true
else
    if [ -f "/usr/share/edk2/${OVMF_ARCH}/OVMF.fd" ]; then
        OVMF_CODE="/usr/share/edk2/${OVMF_ARCH}/OVMF.fd"
        USE_SPLIT=false
    elif [ -f "/usr/share/ovmf/${OVMF_ARCH}/OVMF.fd" ]; then
        OVMF_CODE="/usr/share/ovmf/${OVMF_ARCH}/OVMF.fd"
        USE_SPLIT=false
    elif [ -f "/usr/share/edk2/${OVMF_ARCH}/OVMF_CODE.fd" ]; then
        OVMF_CODE="/usr/share/edk2/${OVMF_ARCH}/OVMF_CODE.fd"
        OVMF_VARS="/usr/share/edk2/${OVMF_ARCH}/OVMF_VARS.fd"
        USE_SPLIT=true
    elif [ -f "/usr/share/ovmf/${OVMF_ARCH}/OVMF_CODE.4m.fd" ]; then
        OVMF_CODE="/usr/share/ovmf/${OVMF_ARCH}/OVMF_CODE.4m.fd"
        OVMF_VARS="/usr/share/ovmf/${OVMF_ARCH}/OVMF_VARS.4m.fd"
        USE_SPLIT=true
    elif [ -f "/usr/share/OVMF/${OVMF_ARCH}/OVMF_CODE_4M.fd" ]; then
        OVMF_CODE="/usr/share/OVMF/${OVMF_ARCH}/OVMF_CODE_4M.fd"
        OVMF_VARS="/usr/share/OVMF/${OVMF_ARCH}/OVMF_VARS_4M.fd"
        USE_SPLIT=true
    else
        echo "Error: OVMF firmware not found for $OVMF_ARCH!"
        exit 1
    fi
fi

echo "Using OVMF firmware at: $OVMF_CODE"
echo "Building for $ARCH_TARGET ($BUILD_TARGET)..."

./snake_build.sh $ARCH_TARGET $BUILD_TARGET || exit $?

BUILD_DIR="../../Build/SnakePkg/${BUILD_TARGET}_GCC5/${ARCH_TARGET}"
ESP_DIR="${BUILD_DIR}/ESP"

rm -rf "$ESP_DIR"
mkdir -p "$ESP_DIR/EFI/BOOT"

if [ ! -f "$BUILD_DIR/Snake.efi" ]; then
    echo "Error: Snake.efi not found at $BUILD_DIR/Snake.efi"
    exit 1
fi

cp "$BUILD_DIR/Snake.efi" "$ESP_DIR/EFI/BOOT/$BOOT_FILE"

QEMU_COMMON="-m 512M -net none -vga std"
QEMU_DEBUG=""
QEMU_ACCEL="-enable-kvm"

if [[ "$DEBUGGER" != "none" ]]; then
    echo "Debug mode enabled ($DEBUGGER)"
    QEMU_DEBUG="-s -S"
    QEMU_ACCEL="-accel tcg"
    echo
    echo "Debugger attach command:"
    if [ "$DEBUGGER" = "gdb" ]; then
        echo "  gdb $BUILD_DIR/Snake.debug"
        echo "  (gdb) target remote :1234"
    elif [ "$DEBUGGER" = "lldb" ]; then
        echo "  lldb $BUILD_DIR/Snake.debug"
        echo "  (lldb) gdb-remote localhost:1234"
    fi
    echo
fi

echo "Starting QEMU ($QEMU_ARCH)..."

if [ "$USE_SPLIT" = true ]; then
    cp "$OVMF_VARS" "$ESP_DIR/OVMF_VARS.fd"

    qemu-system-${QEMU_ARCH} \
        -machine q35 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$ESP_DIR/OVMF_VARS.fd" \
        -drive format=raw,file=fat:rw:$ESP_DIR \
        $QEMU_COMMON $QEMU_ACCEL $QEMU_DEBUG
else
    qemu-system-${QEMU_ARCH} \
        -machine q35 \
        -bios "$OVMF_CODE" \
        -drive format=raw,file=fat:rw:$ESP_DIR \
        $QEMU_COMMON $QEMU_ACCEL $QEMU_DEBUG
fi
