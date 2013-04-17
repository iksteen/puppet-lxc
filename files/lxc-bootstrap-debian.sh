#! /bin/bash

# From: http://www.asahi-net.or.jp/~aa4t-nngk/codes/maskconv
function cidr2oct () {
    local mask bit octs i
    mask=$1

    if grep -q '\.' <<<$mask; then
	echo $mask
	return
    fi

    for ((i=$mask; $i>0; i--)); do
	bit="${bit}1"
    done
    i=$((32 - $mask))
    for ((i=$i; $i>0; i--)); do
	bit="${bit}0"
    done

    octs=$(echo 'ibase=2;obase=A;'$(cut -c 1-8 <<<$bit) |bc)
    octs=${octs}.$(echo 'ibase=2;obase=A;'$(cut -c 9-16 <<<$bit) |bc)
    octs=${octs}.$(echo 'ibase=2;obase=A;'$(cut -c 17-24 <<<$bit) |bc)
    octs=${octs}.$(echo 'ibase=2;obase=A;'$(cut -c 25-32 <<<$bit) |bc)

    echo $octs
}

fatal() {
  echo "fatal: $@"
  exit 1
}

die() {
  [ "x${lxc_rootfs}" != "x" -a -d "${lxc_rootfs}" ] && rm -rf "${lxc_rootfs}"
  fatal $@
}

# Set up defaults
timezone="$(readlink /etc/localtime)"
[ "${LANG}"          ] || LANG=en_US.UTF-8
[ "${timezone}"      ] || timezone=/usr/share/zoneinfo/GMT

# Check environment
[ "${lxc_instance}"  ] || fatal "lxc_instance missing"
[ "${lxc_config}"    ] || fatal "lxc_config missing"
[ "${lxc_rootfs}"    ] || fatal "lxc_rootfs missing"
[ "${lxc_hostname}"  ] || fatal "lxc_hostname missing"
[ "${lxc_ipaddress}" ] || fatal "lxc_ipaddress missing"
[ "${lxc_netmask}"   ] || fatal "lxc_netmask missing"
[ "${lxc_gateway}"   ] || fatal "lxc_gateway missing"
[ "${lxc_release}"   ] || lxc_release=squeeze
# note: ${lxc_puppetserver} is optional
lxc_netmask=$(cidr2oct "${lxc_netmask}")

# Fail if chroot directory already exists
if [ -d "${lxc_rootfs}" ]; then
  fatal "${lxc_rootfs} already exists"
fi

# Create root filesystem path
mkdir -p "${lxc_rootfs}" || die

# Bootstrap the base system
debootstrap --include=locales,netbase,net-tools,iproute \
	"${lxc_release}" "${lxc_rootfs}" || die

# Create a suitable inittab
cat > "${lxc_rootfs}/etc/inittab" <<EOF
id:2:initdefault:
si::sysinit:/etc/init.d/rcS
l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6
z6:6:respawn:/sbin/sulogin
1:2345:respawn:/sbin/getty 38400 console
c1:12345:respawn:/sbin/getty 38400 tty1 linux
p6::ctrlaltdel:/sbin/init 6
p0::powerfail:/sbin/init 0
EOF

# Disable selinux
echo 0 > "${lxc_rootfs}/selinux/enforce"

# Setup hostname
echo "${lxc_hostname}" > "${lxc_rootfs}/etc/hostname"

# Set up locale
sed -ri "s/^# (${LANG} .*)$/\1/" "${lxc_rootfs}/etc/locale.gen" || die
chroot "${lxc_rootfs}" locale-gen || die
chroot "${lxc_rootfs}" update-locale "${LANG}" || die

# Disable services unsuitable for container
for svc in checkrootfs.sh umountfs hwclock.sh hwclockfirst.sh udev udev-mtab; do
  chroot "${lxc_rootfs}" /usr/sbin/update-rc.d -f "${svc}" remove || die
done

# Set up timezone
ln -snf "${timezone}" "${lxc_rootfs}/etc/localtime" || die

# Set up networking
cat >>"${lxc_rootfs}/etc/network/interfaces" <<EOF
auto eth0
iface eth0 inet static
    address ${lxc_ipaddress}
    netmask ${lxc_netmask}
    gateway ${lxc_gateway}
EOF

if [ "x${lxc_puppetserver}" != "x" ]; then
  cd "${lxc_rootfs}/tmp" || die
  wget "http://apt.puppetlabs.com/puppetlabs-release-${lxc_release}.deb" || die
  chroot "${lxc_rootfs}" dpkg -i "/tmp/puppetlabs-release-${lxc_release}.deb" || die
  rm -f "${lxc_rootfs}/tmp/puppetlabs-release-${lxc_release}.deb}" || die
  chroot "${lxc_rootfs}" apt-get update || die
  chroot "${lxc_rootfs}" apt-get install -y puppet || die
  sed -i "s/START=no/START=yes/" "${lxc_rootfs}"/etc/default/puppet" || die
  cat >>"${lxc_rootfs}/etc/puppet/puppet.conf" <<EOF

[agent]
server = ${lxc_puppetserver}
report = true
certname = ${lxc_hostname}
EOF
fi

# Create the lxc lxc_instance
lxc-create -n "${lxc_instance}" -f "${lxc_config}" || die
