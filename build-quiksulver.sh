export PATH="$HOME/zyc-clang/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/zyc-clang/lib"
export BUILD_USERNAME=wo1966
export BUILD_HOSTNAME=remix
export KBUILD_BUILD_USER=wo1966
export KBUILD_BUILD_HOST=remix
SECONDS=0
ZIPNAME="QuicksilveR-ginkgo-KSU-$(date '+%Y%m%d-%H%M').zip"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

if ! [ -d "$HOME/zyc-clang" ]; then
echo "ZyC Clang not found! Cloning..."
wget -q  $(curl https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-14-link.txt 2>/dev/null) -O "ZyC-Clang-14.tar.gz"
mkdir ~/zyc-clang
tar -xf ZyC-Clang-14.tar.gz -C ~/zyc-clang
rm -rf ZyC-Clang-14.tar.gz
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
echo -e "\nClean build!"
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 vendor/ginkgo-ksu_defconfig

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/vendor/ginkgo-ksu_defconfig
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img >> log.txt
fi

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git clone -q https://github.com/Whot1966/AnyKernel3 -b ginkgo/QuicksilveR-KSU
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
rm -rf out/arch/arm64/boot
else
echo -e "\nCompilation failed!"
fi
