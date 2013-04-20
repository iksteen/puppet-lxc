#! /bin/sh

fatal() {
  echo "fatal: $@"
  exit 1
}

die() {
  [ "x${lxc_instance}" != "x" -a -d "${lxc_rootfs}" ] && rm -rf "${lxc_rootfs}"
  fatal $@
}

# Set up defaults
timezone="$(readlink /etc/localtime)"
[ "${LANG}"          ] || LANG=en_US.UTF-8
[ "${timezone}"      ] || timezone=/usr/share/zoneinfo/GMT

# Check environment
[ "${lxc_instance}"  ] || die "lxc_instance missing"
[ "${lxc_config}"    ] || die "lxc_config missing"
[ "${lxc_rootfs}"    ] || die "lxc_rootfs missing"
[ "${lxc_hostname}"  ] || die "lxc_hostname missing"
[ "${lxc_ipaddress}" ] || die "lxc_ipaddress missing"
[ "${lxc_netmask}"   ] || die "lxc_netmask missing"
[ "${lxc_gateway}"   ] || die "lxc_gateway missing"
# note: ${lxc_puppetserver} is optional

# Fail if chroot directory already exists
if [ -d "${lxc_rootfs}" ]; then
  fatal "${lxc_rootfs} already exists"
fi

# Create root filesystem path
mkdir -p "${lxc_rootfs}" || die

# Create custom pacman.conf
pacman_conf="$(mktemp)"
(
  cat >"${pacman_conf}" <<EOF
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[overlay]
SigLevel = Optional TrustAll
Server = http://thegraveyard.org/overlay/i686/
EOF
) || die

# Bootstrap the base system
pacstrap -cC "${pacman_conf}" -d "${lxc_rootfs}" base net-tools || die

cat >>"${lxc_rootfs}/etc/pacman.conf" <<EOF

[overlay]
SigLevel = Optional TrustAll
Server = http://thegraveyard.org/overlay/i686/
EOF

# Disable services unavailable for container
ln -s /dev/null "${lxc_rootfs}/etc/systemd/systemd-udevd.service" || die
ln -s /dev/null "${lxc_rootfs}/etc/systemd/systemd-udevd-control.service" || die
ln -s /dev/null "${lxc_rootfs}/etc/systemd/systemd-udevd-kernel.service" || die
ln -s /dev/null "${lxc_rootfs}/etc/systemd/system/proc-sys-fs-binfmt_misc.automount" || die

# Set up default boot target
ln -snf /usr/lib/systemd/system/multi-user.target "${lxc_rootfs}/etc/systemd/system/default.target"

# Setup hostname
echo "${lxc_hostname}" > "${lxc_rootfs}/etc/hostname"

# Set up locale
echo "LANG=${LANG}" > "${lxc_rootfs}/etc/locale.conf"
sed -i "s/#${LANG}/${LANG}/" "${lxc_rootfs}/etc/locale.gen"
arch-chroot "${lxc_rootfs}" /usr/bin/locale-gen

# Set up timezone
ln -snf "${timezone}" "${lxc_rootfs}/etc/localtime" || die

# Create network configuration
cat >>"${lxc_rootfs}/etc/network.d/eth0" <<EOF
CONNECTION='ethernet'
DESCRIPTION='NATted configuration for lxc container'
INTERFACE='eth0'
IP='static'
ADDR='${lxc_ipaddress}'
NETMASK='${lxc_netmask}'
GATEWAY='${lxc_gateway}'
EOF

ln -snf /usr/lib/systemd/system/netcfg@.service \
	"${lxc_rootfs}/etc/systemd/system/multi-user.target.wants/netcfg@eth0.service" \
	|| die

# Install and configure puppet agent
if [ "x${lxc_puppetserver}" != "x" ]; then
  # Install packages
  pacstrap -C "${pacman_conf}" -d "${lxc_rootfs}" ruby1.8-puppet || die

  # Set up link to master
  (
    cat >>"${lxc_rootfs}/etc/puppet/puppet.conf" <<EOF

    # puppet master
    certname = ${lxc_hostname}
    server = ${lxc_puppetserver}
    report = true
EOF
  ) || die

  # Enable puppet agent service
  ln -snf /usr/lib/systemd/system/puppet.service \
  	"${lxc_rootfs}/etc/systemd/system/multi-user.target.wants/puppet.service" \
  	|| die
fi

# Clean up
rm -f "${pacman_conf}"
