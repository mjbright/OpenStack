
INSTALL_DIR=/root/INSTALL
GIT=/root/src/git/Openstack/HP-Helion-Simple
TOOLS_GIT=${GIT%-Simple}

########################################
# functions:
die() {
    echo "$0 - die: $*" >&2
    exit 1
}

[ `id -un` != 'root' ] && die "Must be run as root"
[     $GIT != `pwd`  ] && die "Expected to be run from dir <$GIT>"

########################################
# main:

echo
echo; echo "Creating ssh key if needed, installing needed packages, restarting libvirtd ..."; echo

# Create root rsa key
[ ! -f /root/.ssh/id_rsa ] && ssh-keygen -t rsa -N ""

# Install required packages:
X11_PACKAGES="xrdp xfce4 libssl-dev libffi-dev virt-manager chromium-browser"
PACKAGES="libvirt-bin openvswitch-switch openvswitch-common python-libvirt qemu-kvm"

# Comment out if X11 packages are not required:
PACKAGES+=" "
PACKAGES+=$X11_PACKAGES

echo "apt-get install -y $PACKAGES"
apt-get install -y $PACKAGES

# Restart libvirt-bin:
/etc/init.d/libvirt-bin restart

########################################
# install these tools:

echo
echo; echo "Installing links to tools in install dir <$INSTALL_DIR>"; echo

[ ! -d $INSTALL_DIR ] && mkdir -p $INSTALL_DIR

cd $INSTALL_DIR

ln -s $GIT/*.sh .
ln -s $TOOLS_GIT/TOOLS.sh .


