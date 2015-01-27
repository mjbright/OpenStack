
die() {
    echo "$0 - die: $*" >&2
    exit 1
}

[ `id -un` != 'root' ] && die "Must be run as root"

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


