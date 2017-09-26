#! /bin/bash
## vim:set ts=4 sw=4 et:
set -e; set -o pipefail

# Run unpacked test files.
# Copyright (C) Markus Franz Xaver Johannes Oberhumer

#set -x # debug
umask 022
argv0=$0; argv0abs=$(readlink -en -- "$0"); argv0dir=$(dirname "$argv0abs")

# IMPORTANT: we need qemu-2.9.1 or better
# change this if you installed qemu-user somewhere else
qemu_prefix=/home/hosts/amd64-linux/packages/qemu-2.10.0/bin/
qemu_prefix=/usr/bin/


check_sha256sums() {
    (cd files/unpacked && sha256sum -b */upx_test* | LC_ALL=C sort -k2) > .sha256sums.current
    if ! cmp -s .sha256sums.expected .sha256sums.current; then
        echo "UPX-ERROR: $1 FAILED: checksum mismatch"
        diff -u .sha256sums.expected .sha256sums.current || true
        exit 1
    fi
}


print_header() {
    printf "\n========== %s\n\n" "$1"
}


run_all_files() {
    local dir="$1"
    local f

    print_header "amd64-linux.elf native"
    for f in $dir/amd64-linux.elf/upx_test*exe*; do
        echo "== $f"
        $f
    done

    print_header "amd64-linux.elf qemu"
    for f in $dir/amd64-linux.elf/upx_test*exe*; do
        echo "== qemu-x86_64 $f"
        ${qemu_prefix}qemu-x86_64 $f
    done

    print_header "arm-linux.elf qemu"
    for f in $dir/arm-linux.elf/upx_test*exe*; do
        echo "== qemu-arm $f"
        ${qemu_prefix}qemu-arm $f
    done

    print_header "armeb-linux.elf qemu"
    for f in $dir/armeb-linux.elf/upx_test*exe*; do
        echo "== qemu-armeb $f"
        ${qemu_prefix}qemu-armeb $f
    done

    print_header "arm64-linux.elf qemu"
    for f in $dir/arm64-linux.elf/upx_test*exe*; do
        echo "== qemu-aarch64 $f"
        ${qemu_prefix}qemu-aarch64 $f
    done

    print_header "i386-linux.elf native"
    for f in $dir/i386-linux.elf/upx_test*exe*; do
        echo "== $f"
        $f
    done

    print_header "i386-linux.elf qemu"
    for f in $dir/i386-linux.elf/upx_test*exe*; do
        echo "== qemu-i386 $f"
        ${qemu_prefix}qemu-i386 $f
    done

    print_header "mips-linux.elf qemu"
    for f in $dir/mips-linux.elf/upx_test*exe*; do
        echo "== qemu-mips $f"
        ${qemu_prefix}qemu-mips $f
    done

    print_header "mipsel-linux.elf qemu"
    for f in $dir/mipsel-linux.elf/upx_test*exe*; do
        echo "== qemu-mipsel $f"
        ${qemu_prefix}qemu-mipsel $f
    done

    print_header "mips64-linux.elf qemu"
    for f in $dir/mips64-linux.elf/upx_test*exe*; do
        echo "== qemu-mips64 $f"
        ${qemu_prefix}qemu-mips64 $f
    done

    print_header "mips64el-linux.elf qemu"
    for f in $dir/mips64el-linux.elf/upx_test*exe*; do
        echo "== qemu-mips64el $f"
        ${qemu_prefix}qemu-mips64el $f
    done

    print_header "mips64-linux-n32.elf qemu"
    for f in $dir/mips64-linux-n32.elf/upx_test*exe*; do
        echo "== qemu-mipsn32 $f"
        ${qemu_prefix}qemu-mipsn32 $f
    done

    print_header "mips64el-linux-n32.elf qemu"
    for f in $dir/mips64el-linux-n32.elf/upx_test*exe*; do
        echo "== qemu-mipsn32el $f"
        ${qemu_prefix}qemu-mipsn32el $f
    done

    print_header "powerpc-linux.elf qemu"
    for f in $dir/powerpc-linux.elf/upx_test*exe*; do
        # INFO: *_dynamic_pie_* files do not work - unsupported relocation (qemu 2.10.0 limitation)
        if [[ $f == *_dynamic_pie_* ]]; then continue; fi
        # INFO: *_static_pie_* files do not work - crash (qemu 2.10.0 bug ?)
        if [[ $f == *_static_pie_* ]]; then continue; fi
        echo "== qemu-ppc $f"
        ${qemu_prefix}qemu-ppc $f
    done

    print_header "powerpc64-linux.elf qemu"
    for f in $dir/powerpc64-linux.elf/upx_test*exe*; do
        # INFO: *_static_pie_* files do not work - hang (qemu 2.10.0 bug ?)
        if [[ $f == *_static_pie_* ]]; then continue; fi
        echo "== qemu-ppc64 $f"
        ${qemu_prefix}qemu-ppc64 $f
    done

    print_header "powerpc64le-linux.elf qemu"
    for f in $dir/powerpc64le-linux.elf/upx_test*exe*; do
        # INFO: *_static_pie_* files do not work - hang (qemu 2.10.0 bug ?)
        if [[ $f == *_static_pie_* ]]; then continue; fi
        echo "== qemu-ppc64le $f"
        ${qemu_prefix}qemu-ppc64le $f
    done

    print_header "s390x-linux.elf qemu"
    for f in $dir/s390x-linux.elf/upx_test*exe*; do
        echo "== qemu-s390x $f"
        ${qemu_prefix}qemu-s390x $f
    done

    print_header "sh-linux.elf qemu"
    for f in $dir/sh-linux.elf/upx_test*exe*; do
        # INFO: *_x.out files (C++) do not work - have to check why
        if [[ $f == *_x.out ]]; then continue; fi
        echo "== qemu-sh4 $f"
        ${qemu_prefix}qemu-sh4 $f
    done

    print_header "sheb-linux.elf qemu"
    for f in $dir/sheb-linux.elf/upx_test*exe*; do
        # INFO: *_x.out files (C++) do not work - have to check why
        if [[ $f == *_x.out ]]; then continue; fi
        echo "== qemu-sheb $f"
        ${qemu_prefix}qemu-sh4eb $f
    done

    echo -e "\nUPX test files in '$dir' run. All done."
}


main() {
    check_sha256sums
    run_all_files files/unpacked
}

main
