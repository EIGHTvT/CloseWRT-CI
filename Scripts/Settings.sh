#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Build date')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")


WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
$WRT_SSID
sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
sed -i "s/$WRT_SSID-2.4G/$WRT_SSID/g" $WIFI_FILE
sed -i "s/$WRT_SSID-5G/${WRT_SSID}_5G/g" $WIFI_FILE
#修改WIFI加密
sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
#修改WIFI密码
sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# 修正设备 ID 冲突 (解决 Image check failed 报错)
# 只精准修改设备定义 ID 和目标列表，不改 DTS 文件名，确保编译不报错
MK_FILE="target/linux/mediatek/image/filogic.mk"
if [ -f "$MK_FILE" ]; then
    sed -i 's/Device\/cmcc_rax3000m-emmc-mtk/Device\/cmcc,rax3000m-emmc/g' $MK_FILE
    sed -i 's/TARGET_DEVICES += cmcc_rax3000m-emmc-mtk/TARGET_DEVICES += cmcc,rax3000m-emmc/g' $MK_FILE
fi

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi
