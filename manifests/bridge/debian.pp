# == Class: lxc::bridge::debian
#
# This class manages the installation of the bridge-utils package and the
# creation, destruction, starting, stopping, enabling and disabling of the
# network profile for the ethernet bridge. You should never have to
# instantiate this yourself, but do take a look at the parameters of
# lxc::bridge and lxc::bridge::linux to control the parameters of the bridge.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
class lxc::bridge::debian(
    $ensure    = $lxc::bridge::ensure,
    $ipaddress = $lxc::bridge::ipaddress,
    $netmask   = $lxc::bridge::netmask,
    $outiface  = $lxc::bridge::outiface,
) inherits lxc::bridge::linux {
  if $::operatingsystem != debian {
    fail("lxc::bridge::debian not supported on ${::operatingsystem}")
  }

  # Make sure bridge-utils is installed
  package { 'bridge-utils':
    ensure => present,
  }

  case $lxc::bridge::ensure {
    /^(running|stopped)$/: {
      $netmask_real = cidr_to_netmask($lxc::bridge::netmask)

      augeas { 'lxc-bridge-main':
        context => '/files/etc/network/interfaces',
        changes => [
          "set iface[. = 'lxc-bridge'] lxc-bridge",
          "set iface[. = 'lxc-bridge']/family inet",
          "set iface[. = 'lxc-bridge']/method static",
          "set iface[. = 'lxc-bridge']/bridge_ports none",
          "set iface[. = 'lxc-bridge']/bridge_stp off",
          "set iface[. = 'lxc-bridge']/bridge_waitport 0",
          "set iface[. = 'lxc-bridge']/bridge_fd 0",
          "set iface[. = 'lxc-bridge']/address ${lxc::bridge::ipaddress}",
          "set iface[. = 'lxc-bridge']/netmask ${netmask_real}",
        ],
      }

      if $ensure == running {
        augeas { 'lxc-bridge-auto':
          context => '/files/etc/network/interfaces',
          changes => [
            "set auto[child::1 = 'lxc-bridge']/1 lxc-bridge",
          ],
        }

        exec { '/sbin/ifup lxc-bridge':
          subscribe   => [
            Augeas['lxc-bridge-main'],
          ],
          refreshonly => true,
        }
      } else {
        exec { '/sbin/ifdown lxc-bridge':
          onlyif => '/bin/grep -e "^auto lxc-bridge$" /etc/network/interfaces',
        }

        augeas { 'lxc-bridge-auto':
          context => '/files/etc/network/interfaces',
          changes => [
            "rm auto[child::1 = 'lxc-bridge']",
          ],
          require => Exec['/sbin/ifdown lxc-bridge'],
        }
      }
    }

    absent: {
      exec { '/sbin/ifdown lxc-bridge':
        onlyif => '/bin/grep -e "^auto lxc-bridge$" /etc/network/interfaces',
      }

      augeas { "lxc-bridge":
        context => "/files/etc/network/interfaces",
        changes => [
          "rm auto[child::1 = 'lxc-bridge']",
          "rm iface[. = 'lxc-bridge']",
        ],
        require => Exec['/sbin/ifdown lxc-bridge'],
      }
    }

    default: {
      fail("lxc::bridge::debian doesn't support ensure => ${lxc::bridge::ensure}")
    }
  }
}
