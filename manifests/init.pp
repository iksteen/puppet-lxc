# == Class: lxc
#
# This class controls the base setup, it ensures the home for the container
# root filesystems exists and installs the lxc package.
#
# === Parameters
#
# [*rootfs_home*]
#   Specify the directory where the root filesystems of the containers will be
#   placed.
#
# === Examples
#
#  class { lxc:
#    rootfs_home => '/srv/lxc',
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
class lxc(
    $rootfs_home = '/srv/lxc',
) {
  file { $rootfs_home:
    ensure => directory,
    mode   => '0700',
    owner  => root,
    group  => root,
  }

  case $::kernel {
    linux:   {}
    default: { fail("lxc not supported on ${::kernel}") }
  }

  case $::operatingsystem {
    archlinux: { include lxc::host::archlinux }
    debian:    { include lxc::host::debian    }
    default: {
      fail("lxc not supported on ${::operatingsystem}")
    }
  }

  file { [$::lxc_basedir, "${::lxc_basedir}/bin"]:
    ensure  => directory,
    mode    => '0755',
    recurse => true,
    purge   => true,
  }
}
