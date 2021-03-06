﻿#!/bin/bash
#
##########################################
####  第三部分：编译WRT和生成R1S固件  ####
##########################################

# 编译 OpenWrt
#cp ../../config.lede ./.config
cp ../../$CONFIG_FILE ./.config
make defconfig
make download
make tools/compile
make toolchain/compile
make package/feeds/luci/luci-base/compile

cp dl/naiveproxy-88.0.4324.96-1.tar.gz build_dir/target-aarch64_cortex-a53_musl/
cd ./build_dir/target-aarch64_cortex-a53_musl/
tar zxvf naiveproxy-88.0.4324.96-1.tar.gz
rm naiveproxy-88.0.4324.96-1.tar.gz
cd ../../
sed -i "s|sys/random.h|/usr/include/linux/random.h|g" build_dir/target-aarch64_cortex-a53_musl/naiveproxy-88.0.4324.96-1/src/base/rand_util_posix.cc

make -j3

# 调整生成SD镜像的脚本
cd ..
cp scripts/build.sh scripts/build.sh.bak

# 删除把img用zip压缩
sed -i '296,299d' scripts/build.sh

# 调整输出R1S的脚本，删除重复编译wrt的步骤
#sed -i '130,150 {/build_friendlywrt/d}' scripts/build.sh
sed -i '130,150 {s/build_friendlywrt/#build_friendlywrt/}' scripts/build.sh

# 为生成SD镜像的脚本加入gzip压缩功能
sed -i "/space/a\\echo 'RAW image successfully compress'" scripts/sd-fuse/mk-sd-image.sh
sed -i "/space/a\\gzip -9 {RAW_FILE}" scripts/sd-fuse/mk-sd-image.sh
sed -i 's/gzip -9 /gzip -9 $/'  scripts/sd-fuse/mk-sd-image.sh
sed -i "/space/a\\echo '---------------------------------'" scripts/sd-fuse/mk-sd-image.sh
sed -i "/space/a\\ " scripts/sd-fuse/mk-sd-image.sh

# 修改代码让其支持使用其他的wrt源码而不是特定的那套
sed -i 's/root-allwinner-h5/root-sunxi/' device/friendlyelec/h5/base.mk

# 正式生成SD镜像
./build.sh nanopi_r1s.mk
