#!/bin/bash

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib
mkdir -p ${PREFIX}/lib/stubs
[[ -d pkg-config ]] && mv pkg-config ${PREFIX}/lib/pkgconfig
[[ -d "$PREFIX/lib/pkgconfig" ]] && sed -E -i "s|cudaroot=.+|cudaroot=$PREFIX|g" $PREFIX/lib/pkgconfig/cuda*.pc

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
# https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html?highlight=tegra#cross-compilation
[[ ${target_platform} == "linux-aarch64" && ${arm_variant_type} == "sbsa" ]] && targetsDir="targets/sbsa-linux"
[[ ${target_platform} == "linux-aarch64" && ${arm_variant_type} == "tegra" ]] && targetsDir="targets/aarch64-linux"

if [ -z "${targetsDir+x}" ]; then
    echo "target_platform: ${target_platform} is unknown! targetsDir must be defined!" >&2
    exit 1
fi

for i in `ls`; do
    [[ $i == "build_env_setup.sh" ]] && continue
    [[ $i == "conda_build.sh" ]] && continue
    [[ $i == "metadata_conda_debug.yaml" ]] && continue
    if [[ $i == "lib" ]] || [[ $i == "include" ]]; then
        # Headers and libraries are installed to targetsDir
        mkdir -p ${PREFIX}/${targetsDir}
        mkdir -p ${PREFIX}/$i
        cp -rv $i ${PREFIX}/${targetsDir}
        if [[ $i == "lib" ]]; then
            for j in "$i"/{*.a,*.so,stubs/*.so}*; do
                # Shared and static libraries are symlinked in $PREFIX/lib
                ln -sv ${PREFIX}/${targetsDir}/$j ${PREFIX}/$j
            done
        fi
    else
        # Put all other files in targetsDir
        mkdir -p ${PREFIX}/${targetsDir}/${PKG_NAME}
        cp -rv $i ${PREFIX}/${targetsDir}/${PKG_NAME}/$i
    fi
done

check-glibc "$PREFIX"/lib*/*.so.* "$PREFIX"/bin/* "$PREFIX"/targets/*/lib*/*.so.* "$PREFIX"/targets/*/bin/*
