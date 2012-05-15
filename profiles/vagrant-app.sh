. profiles/virtualbox-single-disk.sh
. profiles/common/vagrant.sh

stage_uri http://ci.madvertise.me/downloads/amd64/app-current.tar.bz2

post_install() {
	vagrant_post_install
	install_guest_additions
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
