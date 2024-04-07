#!/bin/bash

set -e

for cmd in unzip sha1sum; do
    [ -z "$(command -v "$cmd")" ] && echo "missing $cmd" >&2 && exit 1
done

[ -z "$1" ] && echo "Usage: $0 <zip file>" >&2 && exit 1
FILE="$1"
[ ! -f "$FILE" ] && echo "invalid file $FILE" >&2 && exit 1

ARCH=$(unzip -l "$FILE" | grep -F 'build.prop' | sed -e 's|^.* \(.*\)$|\1|' -e 's|^\(.*\)/.*$|\1|')

getprop() {
    local prop="$1"
    prop=$(sed 's/\./\./g' <<< "$prop")
    unzip -p "$FILE" "$ARCH"/build.prop "$ARCH"/source.properties | \
        grep "^$prop=" | \
        cut -d'=' -f 2-
}

[ "$ARCH" != "$(getprop ro.product.cpu.abi)" -o "$ARCH" != "$(getprop SystemImage.Abi)" ] \
    && echo "ARCH mismatch!" >&2 && exit 1

#SDK=$(getprop ro.build.version.sdk)
SDK=$(getprop AndroidVersion.ApiLevel)
DATE=$(getprop ro.build.date.utc)
DATE=$(date --utc -d @"$DATE" +%Y%m%d)
SHA1=$(sha1sum "$FILE" | cut -d ' ' -f 1)
LVER=$(getprop ro.lineage.build.version | cut -d '.' -f 1)
SIZE=$(stat -c %s "$FILE")
TYPE=phone
getprop ro.build.flavor | grep -q _tv && TYPE=atv
getprop ro.build.flavor | grep -q _car && TYPE=car

declare -x SDK DATE ARCH SIZE SHA1 LVER TYPE
#declare -p SDK DATE ARCH SIZE SHA1 LVER TYPE

envsubst < RemotePackageXMLTemplate.xml
