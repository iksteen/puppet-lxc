# == Resource: lxc::container::debian
#
# This class controls the creation and destruction of a Debian Squeeze
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
#   default is to use the same server this agent uses.
#
# === Examples
#
#  lxc::container::debian { 'lxc_debian01':
#    ensure     => running,
#    ipaddress  => '10.0.0.102',
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
define lxc::container::debian(
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
        fail('lxc::container::debian only supports lxc::bridge::ensure == running')
      }

      require lxc::container::debian::bootstrap

      lxc::container::bootstrap { $instance:
        ensure       => $ensure,
        command      => $lxc::container::debian::bootstrap::bootstrap,
        template     => 'lxc/lxc-debian.erb',
        ipaddress    => $ipaddress,
        rootfs       => $rootfs,
        fqdn         => $lxc_fqdn,
        puppetserver => $puppetserver,
      }
    }

    absent: {
      lxc::container::bootstrap { $instance:
        ensure       => $ensure,
        command      => '',
        template     => 'lxc/lxc-debian',
        ipaddress    => $ipaddress,
        rootfs       => $rootfs,
        fqdn         => $lxc_fqdn,
        puppetserver => $puppetserver,
      }
    }

    default: {
      fail("lxc::container::debian does not support ensure => ${ensure}")
    }
  }
}
