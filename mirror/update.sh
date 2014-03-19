#!/bin/bash -xev

mirror=ftp.br.debian.org
distributions=jessie
archs=i386,amd64,all
sections=main,contrib,non-free
target=debian

function update_mirror() {
	mirror=${1}
	distributions=${2}
	archs=${3}
	sections=${4}
	target=${5}
	$(which debmirror) --debug --verbose --progress \
	--host=${mirror:=ftp.us.debian.org} \
	--dist=${distributions:=stable} \
	--arch=${archs:=i386} \
	--section=${sections:=main} \
	--method=rsync \
	--getcontents \
	--progress \
	--nosource \
	--ignore-missing-release \
	--ignore-release-gpg \
	--ignore-small-errors \
	--root=:debian \
	${target:=debian}/
}

# regular mirror
#update_mirror ${mirror} ${distributions} ${archs} ${sections} ${target}

# just "non-official" packages now and their binaries
distributions=jessie-updates,jessie-backports
archs=i386,amd64

update_mirror ${mirror} ${distributions} ${archs} ${sections} ${target}

exit 0
