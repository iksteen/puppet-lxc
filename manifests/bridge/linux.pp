# == Class: lxc::bridge::linux
#
# This class manages the basic properties of the ethernet bridge that acts
# as a private network for the containers. It manages IP forwarding on the
# kernel and sets up masquerading using iptables through the puppetlabs
# firewall module. Used internally, you never have to declare it yourself
# although you might want to change the parameters.
#
# === Parameters
#
# [*forward*]
#   Specify wether to manage the net.ipv4.ip_forward sysctl value.
#
# [*masquerade*]
#   Specify wether to enable masquerading using puppetlabs-firewall.
#
# === Examples
#
#  class { lxc::bridge::linux:
#    forward    => false,
#    masquerade => false,
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
class lxc::bridge::linux(
    $forward    = false,
    $masquerade = false,
) {
  if $::kernel != linux {
    fail("lxc::bridge::linux not supported on ${::kernel}")
  }

  case $lxc::bridge::ensure {
    running: {
      $forward_value = 1
      $firewall_ensure = present
    }
    /^(stopped|absent)$/: {
      $forward_value = 0
      $firewall_ensure = absent
    }
    default: {
      fail("lxc::bridge::linux doesn't support ensure => ${lxc::bridge::ensure}")
    }
  }

  # If enabled, ensure ip_forwarding is active.
  if $forward {
    sysctl { 'net.ipv4.ip_forward':
      ensure    => present,
      permanent => yes,
      value     => $forward_value,
    }
  }

  # Set up masquerading.
  if $masquerade {
    firewall { '100 snat for lxc-bridge':
      ensure   => $firewall_ensure,
      chain    => 'POSTROUTING',
      jump     => 'MASQUERADE',
      proto    => 'all',
      outiface => $lxc::bridge::outiface,
      source   => "${lxc::bridge::ipaddress}/${lxc::bridge::netmask}",
      table    => 'nat'
    }
  }
}
