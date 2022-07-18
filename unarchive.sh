#!/bin/bash

# clean
test -d parcel && rm -rvf parcel

# make
mkdir parcel

for list in $(find . -name "*.rpm")
do
 rpmname=$(basename $list)
 version=$(echo $rpmname | grep -o '\-[[:digit:]].*')
 location=$(echo $rpmname | sed "s/$version//g")

 # explode
 mkdir -p parcel/$location
 pushd parcel/$location
 rpm2cpio ../../$list | cpio -idv
 popd
 echo "$rpmname :: $version :: $location"
done
