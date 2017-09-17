#! /bin/bash
## vim:set ts=4 sw=4 et:
set -e; set -o pipefail
#set -x # debug
umask 022
argv0=$0; argv0abs=$(readlink -en -- "$0"); argv0dir=$(dirname "$argv0abs")

#
# required unpacked files:
#
#   https://github.com/upx/upx-stubtools/releases/download/v20160918/bin-upx-20160918.tar.xz
#   https://github.com/upx/upx-stubtools/releases/download/v20160918/upx-linux-musl-gcc-7.2.0-toolchains-20170914.tar.xz
#
#  WARNING: these are rather huge archives and require > 10 GiB of disk space when unpacked
#

search_dir() {
    local subdir="$1"
    local d
    dir=
    for d in "$HOME/local/bin" "$HOME/.local/bin" "$HOME/bin" /usr/local/bin /usr/local/packages; do
        if [[ -d "$d/$subdir" ]]; then
            dir=$d
            break
        fi
    done
}


# set gcc, gxx, dynlink_flags, rpath_flags
set_gcc() {
    local x fixed_prefix
    x=linux-musl-gcc-7.2.0-20170914/$tc-gcc-7.2.0
    if [[ $1 == pie ]]; then
        x=linux-musl-gcc-7.2.0-20170914-default-pie/$tc-gcc-7.2.0
    fi
    gcc=$d_toolchains/$x/bin/$tc-gcc
    gxx=$d_toolchains/$x/bin/$tc-g++
    if [[ ! -f $d_toolchains/$x/$tc/lib/$dynlink_name ]]; then
        echo "BAD dynlink $x/$tc/lib/$dynlink_name"
        exit 1
    fi
    # NOTE: to ensure reproducibility we set a fixed dynamic linker and rpath in /usr/local/bin
    fixed_prefix=/usr/local/bin/upx-linux-musl-gcc-7.2.0-toolchains-20170914
    dynlink_flags="-Wl,--dynamic-linker=$fixed_prefix/$x/$tc/lib/$dynlink_name"
    rpath_flags="-Wl,--rpath=$fixed_prefix/$x/$tc/lib"
}


run_gcc() {
    #echo "$@"
    "$@"
}


build_arch() {
    local src_c src_x odir oprefix tc dynlink_name
    local gcc gxx cppflags cflags cxxflags ldflags libs clibs cxxlibs
    local x

    printf "===== %-10s  %-22s  %s\n" $1 $2 $3

    src_c=src/$1_c*.c
    src_x=src/$1_x*.cpp
    odir=files/unpacked/$2
    oprefix=$odir/$1
    tc=$3
    dynlink_name=$4
    shift 4
    if [[ $# -gt 0 ]]; then
        oprefix="${oprefix}$1"
        shift
    fi

    mkdir -p $odir

    cflags="-pthread -O2 -Wall -W -Wcast-align -Wcast-qual -pedantic"
    cxxflags="$cflags"
    ldflags="-s -Wl,--build-id=none"

    set_gcc default

    # dll
    x="$1 -shared -fPIC $dynlink_flags $rpath_flags"
    run_gcc $gcc $x $cppflags $cflags   $ldflags -DDLL -o ${oprefix}_dll_c.so $src_c $libs $clibs
    run_gcc $gxx $x $cppflags $cxxflags $ldflags -DDLL -o ${oprefix}_dll_x.so $src_x $libs $cxxlibs

    # exe
    x="$1 $dynlink_flags $rpath_flags"
    run_gcc $gcc $x $cppflags $cflags   $ldflags -o ${oprefix}_exe_dynamic_nopie_c.out $src_c $libs $clibs
    run_gcc $gxx $x $cppflags $cxxflags $ldflags -o ${oprefix}_exe_dynamic_nopie_x.out $src_x $libs $cxxlibs
    # static exe
    x="$1 -static"
    run_gcc $gcc $x $cppflags $cflags   $ldflags -o ${oprefix}_exe_static_nopie_c.out $src_c $libs $clibs
    run_gcc $gxx $x $cppflags $cxxflags $ldflags -o ${oprefix}_exe_static_nopie_x.out $src_x $libs $cxxlibs

    set_gcc pie

    # exe (-fPIE via --enable-default-pie toolchain)
    x="$1 $dynlink_flags $rpath_flags"
    run_gcc $gcc $x $cppflags $cflags   $ldflags -o ${oprefix}_exe_dynamic_pie_c.out $src_c $libs $clibs
    run_gcc $gxx $x $cppflags $cxxflags $ldflags -o ${oprefix}_exe_dynamic_pie_x.out $src_x $libs $cxxlibs
    # static exe (-fPIE via --enable-default-pie toolchain)
    x="$1 -static"
    run_gcc $gcc $x $cppflags $cflags   $ldflags -o ${oprefix}_exe_static_pie_c.out $src_c $libs $clibs
    run_gcc $gxx $x $cppflags $cxxflags $ldflags -o ${oprefix}_exe_static_pie_x.out $src_x $libs $cxxlibs
}


build() {
    build_arch $1 amd64-linux.elf        x86_64-linux-musl       ld-musl-x86_64.so.1
    build_arch $1 arm-linux.elf          arm-linux-musleabi      ld-musl-arm.so.1           "_sf_a" "-marm"
    build_arch $1 arm-linux.elf          arm-linux-musleabi      ld-musl-arm.so.1           "_sf_t" "-mthumb"
    build_arch $1 arm-linux.elf          arm-linux-musleabihf    ld-musl-armhf.so.1         "_hf_a" "-march=armv6 -marm"
    build_arch $1 arm-linux.elf          arm-linux-musleabihf    ld-musl-armhf.so.1         "_hf_t" "-march=armv6t2 -mthumb"
    build_arch $1 arm64-linux.elf        aarch64-linux-musl      ld-musl-aarch64.so.1
    build_arch $1 arm64eb-linux.elf      aarch64_be-linux-musl   ld-musl-aarch64_be.so.1
    build_arch $1 armeb-linux.elf        armeb-linux-musleabi    ld-musl-armeb.so.1         "_sf_a" "-marm"
    build_arch $1 armeb-linux.elf        armeb-linux-musleabi    ld-musl-armeb.so.1         "_sf_t" "-mthumb"
    build_arch $1 armeb-linux.elf        armeb-linux-musleabihf  ld-musl-armebhf.so.1       "_hf_a" "-march=armv6 -marm"
    build_arch $1 armeb-linux.elf        armeb-linux-musleabihf  ld-musl-armebhf.so.1       "_hf_t" "-march=armv6t2 -mthumb"
    build_arch $1 i386-linux.elf         i586-linux-musl         ld-musl-i386.so.1          "_i586"
    build_arch $1 i386-linux.elf         i686-linux-musl         ld-musl-i386.so.1          "_i686" "-msse2"
####build_arch $1 microblaze-linux.elf   microblaze-linux-musl   ld-musl-microblaze.so.1
####build_arch $1 microblazeel-linux.elf microblazeel-linux-musl ld-musl-microblazeel.so.1
    build_arch $1 mips-linux.elf         mips-linux-musl         ld-musl-mips.so.1          "_hf"
    build_arch $1 mips64-linux.elf       mips64-linux-musl       ld-musl-mips64.so.1        "_hf"
    build_arch $1 mips64el-linux.elf     mips64el-linux-musl     ld-musl-mips64el.so.1      "_hf"
    build_arch $1 mipsel-linux.elf       mipsel-linux-musl       ld-musl-mipsel.so.1        "_hf"
    build_arch $1 powerpc-linux.elf      powerpc-linux-musl      ld-musl-powerpc.so.1       "_hf"
    build_arch $1 powerpc-linux.elf      powerpc-linux-muslsf    ld-musl-powerpc-sf.so.1    "_sf"
    build_arch $1 powerpc64-linux.elf    powerpc64-linux-musl    ld-musl-powerpc64.so.1
    build_arch $1 powerpc64le-linux.elf  powerpc64le-linux-musl  ld-musl-powerpc64le.so.1
    build_arch $1 s390x-linux.elf        s390x-linux-musl        ld-musl-s390x.so.1
    build_arch $1 sh-linux.elf           sh-linux-musl           ld-musl-sh-nofpu.so.1      "_sf"
    build_arch $1 sheb-linux.elf         sheb-linux-musl         ld-musl-sheb-nofpu.so.1    "_sf"
    # ILP32 toolchains on 64-bit machines
    build_arch $1 amd64-linux-x32.elf    x86_64-linux-muslx32    ld-musl-x32.so.1
    build_arch $1 mips64-linux-n32.elf   mips64-linux-musln32    ld-musl-mipsn32.so.1       "_hf"
    build_arch $1 mips64el-linux-n32.elf mips64el-linux-musln32  ld-musl-mipsn32el.so.1     "_hf"
}


main() {
    search_dir bin-upx/packages/clang-3.9.0-20160902
    if [[ -z $dir ]]; then
        echo "$argv0: ERROR: 'bin-upx' not found"
        exit 1
    fi
    d_bin_upx=$dir/bin-upx
    echo "info: found bin_upx=$d_bin_upx"

    $d_bin_upx/upx-stubtools-check-version 20160918

    search_dir upx-linux-musl-gcc-7.2.0-toolchains-20170914/linux-musl-gcc-7.2.0-20170914/x86_64-linux-musl-gcc-7.2.0
    if [[ -z $dir ]]; then
        echo "$argv0: ERROR: 'upx-linux-musl-gcc-7.2.0-toolchains-20170914' not found"
        exit 1
    fi
    d_toolchains=$dir/upx-linux-musl-gcc-7.2.0-toolchains-20170914
    echo "info: found toolchains=$d_toolchains"

    build upx_test01

    (cd files/unpacked && sha256sum -b */upx_test* | LC_ALL=C sort -k2) > .sha256sums.current
    if ! cmp -s .sha256sums.expected .sha256sums.current; then
        echo "UPX-ERROR: $1 FAILED: checksum mismatch"
        diff -u .sha256sums.expected .sha256sums.current || true
        exit 1
    fi

    echo "UPX test files built. All done."
}

main
