#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
#sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Build date')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")


WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
if [ -f "$WIFI_FILE" ]; then
   sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
   sed -i "s/$WRT_SSID-2.4G/$WRT_SSID/g" $WIFI_FILE
   sed -i "s/$WRT_SSID-5G/${WRT_SSID}_5G/g" $WIFI_FILE
#修改WIFI加密
   sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
#修改WIFI密码
   sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\tset wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# 核心修正：不改主 ID 确保编译通过，只改生成的元数据确保网页升级通过
MK_FILE="target/linux/mediatek/image/filogic.mk"

if [ -f "$MK_FILE" ]; then
    echo "正在执行兼容性修正..."
    # 1. 确保主 ID 维持原样 (下划线版)，防止编译报错
    # 2. 在配置块内，增加兼容设备列表 (这是最高效且不破坏编译的办法)
    # 我们直接定位到 rax3000m 的配置块，添加 SUPPORTED_DEVICES
    sed -i '/Device\/cmcc_rax3000m-emmc-mtk/,/endef/ s/SUPPORTED_DEVICES +=/SUPPORTED_DEVICES += cmcc,rax3000m-emmc /' "$MK_FILE"
    
    # 3. 预防万一：如果该 Makefile 比较特殊，强制插入一行
    if ! grep -q "cmcc,rax3000m-emmc" "$MK_FILE"; then
        sed -i '/DEVICE_DTS := mt7981b-cmcc-rax3000m-emmc-mtk/a \\tSUPPORTED_DEVICES += cmcc,rax3000m-emmc' "$MK_FILE"
    fi
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
