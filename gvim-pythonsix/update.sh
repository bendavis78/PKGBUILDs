#!/bin/bash
echo "Checking new version..."
versionstr=$(pacman -Si gvim | grep ^Version) || exit 1
pattern='([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)'

if [[ ! $versionstr =~ $pattern ]]; then
    echo "Cound not parse version: '$versionstr'"
    exit 1
fi

new_version_maj="${BASH_REMATCH[1]}"
new_version_min="${BASH_REMATCH[2]}"
new_patchlevel="${BASH_REMATCH[3]}"
new_pkgrel="${BASH_REMATCH[4]}"
new_pkgver="${new_version_maj}.${new_version_min}.${new_patchlevel}"

. PKGBUILD || exit 1;

if [[ "${pkgver}" == "${new_pkgver}" ]]; then
    echo "PKGBUILD version ($new_pkgver) is up to date.";
    exit 1;
fi

echo "Updating MD5 checksums..."
for i in $(seq 0 $(( ${#source[@]} - 1))); do
    url="${source[$i]/$pkgver/$new_pkgver}";
    if [[ "${md5sums[$i]}" != "SKIP" ]]; then
        if [[ ! -f "${url##*/}" ]]; then
            wget "${url}";
        fi
        md5sums[$i]=$(md5sum "${url##*/}" | cut -d' ' -f1);
    else
        md5sums[$i]="SKIP";
    fi
done

new_checksums=$(printf '         "%s"\n' "${md5sums[@]}");

cp PKGBUILD PKGBUILD.new

perl -p -i -e "s/_topver=.*/_topver=\"${new_version_maj}.${new_version_min}\"/" PKGBUILD.new || exit 1;
perl -p -i -e "s/_patchlevel=.*/_patchlevel=\"${new_patchlevel}\"/" PKGBUILD.new || exit 1;
perl -0777 -p -i -e 's/^md5sums=\(.*?\)$/md5sums=('"${new_checksums:9}"')/sm' PKGBUILD.new  || exit 1;

mv PKGBUILD PKGBUILD.bak || exit 1;
mv PKGBUILD.new PKGBUILD || exit 1;

. PKGBUILD || exit 1;

echo "Successfully updated PKGBUILD.";
echo "topver:      ${_topver}";
echo "patchlevel:  ${_patchlevel}";

echo;
echo "Making AUR source package...";
mkaurball -Sf || exit 1;

echo "Uploading to AUR...";
aurploader -akc ~/.config/aurcookies
