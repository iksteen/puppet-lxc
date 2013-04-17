# == Resource: lxc::container::archlinux
#
# This class controls the creation and destruction of an Arch Linux
# container.
#
# === Parameters
#
# [*ensure*]
#   Specify the state the container should be in. Either running, stopped
#   or absent.
#
# [*instance*]
#   Specify the instance name of the container. Defaults to $title.
#
# [*ipaddress*]
#   Specify the IP address the container should use. Note that you can't
#   change this after the container has been bootstrapped.
#
# [*rootfs*]
#   Specify the path where the root filesystem will be created. The default
#   is ${lxc::rootfs_home}/${instance}.
#
# [*lxc_fqdn*]
#   Specify the fqdn to preconfigure the container to use. Defaults to
#   ${instance}.${::domain}.
#
# [*puppetserver*]
#   Specify the puppet server to preconfigure the container to connect to. The
#   default is to use the same server as this agent uses.
#
# === Examples
#
#  lxc::container::archlinux { 'lxc_arch01':
#    ensure     => running,
#    ipaddress  => '10.0.0.101',
#  }
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
define lxc::container::archlinux(
    $ensure,
    $ipaddress,
    $instance      = $title,
    $rootfs        = undef,
    $lxc_fqdn      = undef,
    $puppetserver  = $::lxc_puppetserver,
) {
  case $ensure {
    /^(running|stopped)$/: {
      include lxc::bridge

      if $ensure == running and $lxc::bridge::ensure != running {
        fail('lxc::container::archlinux only supports lxc::bridge::ensure == running')
      }

      require lxc::container::archlinux::bootstrap

      lxc::container::bootstrap { $instance:
        ensure       => $ensure,
        command      => $lxc::container::archlinux::bootstrap::bootstrap,
        template     => 'lxc/lxc-archlinux.erb',
        ipaddress    => $ipaddress,
        rootfs       => $rootfs,
        fqdn         => $lxc_fqdn,
        puppetserver => $puppetserver,
      }
    }

    absent: {
      lxc::container::bootstrap { $instance:
        ensure       => $ensure,
        template     => 'lxc/lxc-archlinux',
        ipaddress    => $ipaddress,
        rootfs       => $rootfs,
        fqdn         => $lxc_fqdn,
        puppetserver => $puppetserver,
      }
    }

    default: {
      fail("lxc::container::archlinux does not support ensure => ${ensure}")
    }
  }
}
