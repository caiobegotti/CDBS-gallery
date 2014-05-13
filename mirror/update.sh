#!/bin/bash -xv
# gpgv: can't check signature: public key not found
# cp /usr/share/keyrings/debian-archive-keyring.gpg ~/.gnupg/trustedkeys.gpg
# gpg --keyring /usr/share/keyrings/debian-archive-keyring.gpg --export | gpg --no-default-keyring --keyring trustedkeys.gpg --import
# gpg --keyserver hkp://subkeys.pgp.net --recv-keys A040830F7FAC5991

archive_mirror=archive.debian.org
mirror=ftp.br.debian.org

# FIXME: lenny's archive is asking for an anonymous password
archive_distributions=etch,sarge,woody
distributions=sid,jessie,wheezy,squeeze

archive_sections=main,contrib,non-free
sections=main,contrib,non-free

archive_method=http
method=rsync

function _debmirror() {
	debmirror \
		--host=${1} \
		--dist=${2} \
		--section=${3} \
		--method=${4} \
		--getcontents \
		--source \
		--progress \
		--arch=none \
		--no-check-gpg \
		--ignore-missing-release \
		--ignore-release-gpg \
		--ignore-small-errors \
		--root=:debian \
		debian/
}

_debmirror ${archive_mirror} ${archive_distributions} ${archive_sections} ${archive_method}

_debmirror ${mirror} ${distributions} ${sections} ${method}

exit 0
