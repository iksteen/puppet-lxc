# == Class: lxc::bridge::archlinux
#
# This class manages the installation of the bridge-utils package and the
# creation, destruction, starting, stopping, enabling and disabling of the
# netcfg profile for the ethernet bridge on Arch Linux. You should never
# have to instantiate this yourself, but do take a look at the parameters
# of lxc::bridge and lxc::bridge::linux to control the parameters of the
# bridge.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
class lxc::bridge::archlinux(
) inherits lxc::bridge::linux {
  if $::operatingsystem != archlinux {
    fail("lxc::bridge::archlinux not supported on ${::operatingsystem}")
  }

  # Make sure bridge-utils is installed
  package { 'bridge-utils':
    ensure => present,
  }

  case $lxc::bridge::ensure {
    running: {
      $bridge_ensure  = present
      $service_ensure = running
      $service_enable = true
    }
    stopped: {
      $bridge_ensure  = present
      $service_ensure = stopped
      $service_enable = false
    }
    absent: {
      $bridge_ensure  = absent
      $service_ensure = stopped
      $service_enable = false
    }
    default: {
      fail("lxc::bridge::linux doesn't support ensure => ${lxc::bridge::ensure}")
    }
  }

  # Create the bridge netcfg profile
  file { '/etc/network.d/lxc-bridge':
    ensure  => $bridge_ensure,
    mode    => '0644',
    owner   => root,
    group   => root,
    content => template('lxc/lxc-bridge.archlinux.erb'),
    notify  => Service['netcfg@lxc-bridge'],
  }

  # Enable the netcfg service for the bridge
  service { 'netcfg@lxc-bridge':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['bridge-utils'],
  }

}
