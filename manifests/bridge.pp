# == Class: lxc::bridge
#
# This class controls the creation and destruction of an ethernet bridge. The
# bridge is used as a private subnet for the lxc containers and will be
# connected to the WAN (or LAN) using NAT. This class includes the bridge
# class suitable for the running operatingsystem.
#
# === Parameters
#
# [*ensure*]
#   Specify the state the bridge should be in. Either running, stopped
#   or absent. Defaults to running.
#
# [*ipaddress*]
#   Specify the IP address of the host on the ethernet bridge. This is
#   also the gateway IP address for the containers. Defaults to 10.0.0.1.
#
# [*netmask*]
#   Specify the netmask for the network on the bridge. Defaults to 24.
#
# [*outiface*]
#   Specify through which interface on the host outgoing traffic of the
#   containers should be routed. This defaults to the interface that
#   has the IP address equal to the $::ipaddress fact.
#
# === Examples
#
#  class { 'lxc::bridge':
#    ensure     => running,
#    ipadddress => '10.0.0.1',
#    netmask    => 24,
#    outiface   => eth0,
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
class lxc::bridge(
    $ensure    = running,
    $ipaddress = '10.0.0.1',
    $netmask   = 24,
    $outiface  = $::lxc_defoutiface,
) {
  include lxc

  case $::operatingsystem {
    archlinux: { include lxc::bridge::archlinux }
    debian:    { include lxc::bridge::debian    }
    default:   {
      fail("lxc::bridge not supported on ${::operatingsystem}")
    }
  }
}
