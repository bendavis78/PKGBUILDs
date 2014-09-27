#!/bin/bash
versionstr=$(pacman -Si gvim | grep ^Version) || exit 1
pattern='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'

if [[ ! $versionstr =~ $pattern ]]; then
    echo "Cound not parse version: '$versionstr'"
    exit 1
fi

version_maj="${BASH_REMATCH[1]}"
version_min="${BASH_REMATCH[2]}"
patchlevel="${BASH_REMATCH[3]}"
pkgrel="${BASH_REMATCH[4]}"
hgrev="v${version_maj}-${version_min}-${patchlevel}"

sed -i -e "s/_topver=.*/_topver=\"${version_maj}.${version_min}\"/" PKGBUILD || exit1
sed -i -e "s/_patchlevel=.*/_patchlevel=\"$patchlevel\"/" PKGBUILD || exit 1
sed -i -e "s/__hgrev=.*/__hgrev=\"${hgrev}\"/" PKGBUILD || exit 1

echo "Getting MD5 checksums..."


. PKGBUILD

echo "Successfully updated PKGBUILD.";
echo "topver:      ${_topver}";
echo "patchlevel:  ${_patchlevel}";
echo "hgrev:       ${__hgrev}";

echo
echo "Building package..."
