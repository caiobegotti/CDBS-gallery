#!/bin/bash -e
# gpgv: can't check signature: public key not found
# cp /usr/share/keyrings/debian-archive-keyring.gpg ~/.gnupg/trustedkeys.gpg
# gpg --keyring /usr/share/keyrings/debian-archive-keyring.gpg --export | gpg --no-default-keyring --keyring trustedkeys.gpg --import
# gpg --keyserver hkp://subkeys.pgp.net --recv-keys A040830F7FAC5991

mirror=ftp.us.debian.org
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
	$(which debmirror) --verbose --progress \
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
update_mirror ${mirror} ${distributions} ${archs} ${sections} ${target}

mirror=ftp.br.debian.org
distributions=jessie-updates,jessie-backports
archs=i386,amd64
sections=main,contrib,non-free
target=debian

# just "non-official" packages now, only binaries
update_mirror ${mirror} ${distributions} ${arch} ${sections} ${target}

exit 0
