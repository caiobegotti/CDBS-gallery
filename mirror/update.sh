#!/bin/bash
# gpgv: can't check signature: public key not found
# cp /usr/share/keyrings/debian-archive-keyring.gpg ~/.gnupg/trustedkeys.gpg

mirror=ftp.br.debian.org
distribution=sid
sections=main,contrib,non-free

debmirror \
	--host=${mirror} \
	--dist=${distribution} \
	--section=${sections} \
	--method=rsync \
	--getcontents \
	--source \
	--progress \
	--arch=none \
	--ignore-missing-release \
	--ignore-release-gpg \
	--ignore-small-errors \
	--root=:debian \
	debian/

exit 0
