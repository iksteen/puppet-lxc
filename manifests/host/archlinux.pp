# == Class: lxc::host::archlinux
#
# This class prepares an Arch Linux host for running containers. You do not
# have to include this class yourself.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
class lxc::host::archlinux {
  package { 'lxc':
    ensure => installed,
  }
}
