# == Class: lxc::container::debian::bootstrap
#
# This is an internal class that makes sure the bootstrap script is present
# on the client and that any requirements to run the scripts are installed.
# You should never have to include this yourself but if you're implementing
# support for this container for a new host type, you can edit this to
# ensure the required packages are present.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
class lxc::container::debian::bootstrap {
  $bootstrap  = "${::lxc_basedir}/bin/lxc-bootstrap-debian.sh"

  file { $bootstrap:
    ensure => file,
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/lxc/lxc-bootstrap-debian.sh',
  }

  case $::operatingsystem {
    archlinux: {
      package { 'debootstrap':
        ensure => installed,
      }

      package { 'gnupg1':
        ensure => installed,
      }

      package { 'debian-archive-keyring':
        ensure => installed,
      }

      package { 'bc':
        ensure => installed,
      }
    }

    debian: {
      package { 'debootstrap':
        ensure => installed,
      }

      package { 'bc':
        ensure => installed,
      }

      package { 'bash':
        ensure => installed,
      }
    }

    default: {
      fail("lxc::container::debian not supported on ${::operatingsystem}")
    }
  }
}
