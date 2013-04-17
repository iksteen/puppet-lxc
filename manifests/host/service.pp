# == Resource: lxc::host::service
#
# This resource is used internally to set up the services to start the
# container. Unless you are implementing support for a new host operating
# system this class will be of no interest to you.
#
# === Parameters
#
# [*ensure*]
#   Specify the of the service (running, stopped, absent).
#
# [*instance*]
#   The name of the container instance to manage the service for.
#
# [*rootfs*]
#   Specify the location of the root filesystem of the container.
#
# [*config*]
#   Specify the configuration file to create a service for.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
define lxc::host::service(
    $ensure,
    $rootfs,
    $config,
    $instance = $title,
) {
  case $::operatingsystem {
    archlinux: {
      lxc::host::archlinux::service { $instance:
        ensure => $ensure,
        rootfs => $rootfs,
        config => $config,
      }
    }

    debian: {
      lxc::host::debian::service { $instance:
        ensure => $ensure,
        rootfs => $rootfs,
        config => $config,
      }
    }

    default: {
      fail("lxc::host::service not supported on ${::operatingsystem}")
    }
  }
}
