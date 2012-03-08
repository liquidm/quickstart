. profiles/virtualbox-single-disk.sh
. profiles/common/vagrant.sh

stage_uri http://www.zentoo.org/downloads/amd64/chef-server-current.tar.bz2

post_install() {
	vagrant_post_install
	compact_with_cleanup
	compact_with_zero_fill

	# do not return with failure
	true
}
