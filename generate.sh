#!/usr/bin/env bash

set -e

data_url="https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json"
out_path="src/lib.zig"
file=$(curl -s $data_url)

do_print() {
    echo $@ >> $out_path
}
print_tab() {
    printf "    " >> $out_path
}
do_filter() {
    echo $file | jq --raw-output --compact-output "$1"
}
sub_filter() {
    echo "$1" | jq --raw-output --compact-output "$2"
}

echo "// SPDX License Data generated from https://github.com/spdx/license-list-data" > $out_path
do_print "//"
do_print "//" "Last generated from version" $(do_filter '.licenseListVersion')
do_print "//"

#
#
do_print
do_print "pub const License = struct {"
print_tab; do_print "isOsiApproved: bool,"
print_tab; do_print "isFsfLibre: bool,"
print_tab; do_print "url: []const u8,"
do_print "};"

#
#
echo "spdx:"
do_print
do_print "pub const spdx = struct {"
list=$(do_filter '.licenses | sort_by(.licenseId)[] | { licenseId, isOsiApproved, isFsfLibre, url:.seeAlso[0] }')
for lic in $list
do
    lic_id=$(sub_filter $lic '.licenseId')

    lic_obj=$(sub_filter $lic '{ isOsiApproved, isFsfLibre, url }')
    lic_obj=${lic_obj//\":/ = }
    lic_obj=${lic_obj//,\"/, .}
    lic_obj=${lic_obj//\{\"/\{\.}
    lic_obj=${lic_obj//null/false}

    printf "    " >> $out_path
    do_print "pub const @\"$lic_id\" = License$lic_obj;"
    printf "|"
done
do_print "};"
echo

#
#
echo "osi:"
do_print
do_print "pub const osi = &[_][]const u8{"
for lic in $list
do
    lic_id=$(sub_filter $lic '.licenseId')
    valid=$(sub_filter $lic '.isOsiApproved')
    if [[ $valid == "true" ]]
    then
        print_tab; do_print "\"$lic_id\","
    fi
    printf "|"
done
do_print "};"
echo

#
#
echo "fsf:"
do_print
do_print "pub const fsf = &[_][]const u8{"
for lic in $list
do
    lic_id=$(sub_filter $lic '.licenseId')
    valid=$(sub_filter $lic '.isFsfLibre')
    if [[ $valid == "true" ]]
    then
        print_tab; do_print "\"$lic_id\","
    fi
    printf "|"
done
do_print "};"
echo
