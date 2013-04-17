# == Resource: lxc::host::archlinux::service
#
# This resource ensures the create, deletion, starting, stopping and
# enabled state of services that control a container on an Arch Linux
# host platform. It is used internally and you should never have to
# create an instance yourself.
#
# === Parameters
#
# [*ensure*]
#   Specify the desired state of the service (running, stopped, absent).
#   or absent. Defaults to running.
#
# [*instance*]
#   Specify the container instance this resource manages.
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
define lxc::host::archlinux::service(
    $ensure,
    $rootfs,
    $config,
    $instance = $title,
) {
  if $::operatingsystem != archlinux {
    fail("lxc::host::archlinux not supported on ${::operatingsystem}")
  }

  $service = "lxc-instance-${instance}"
  $service_file = "/etc/systemd/system/${service}.service"

  case $ensure {
    /^(running|stopped)$/: {
      $svc_enable = $ensure ? {
        running => true,
        stopped => false,
      }

      file { $service_file:
        ensure  => file,
        mode    => '0644',
        owner   => root,
        group   => root,
        content => template('lxc/lxc-service.erb'),
      }

      exec { "systemd reload for ${service}":
        command     => '/usr/bin/systemctl daemon-reload',
        subscribe   => File[$service_file],
        refreshonly => true,
      }

      service { $service:
        ensure  => $ensure,
        enable  => $svc_enable,
        require => [
          File[$service_file],
          Exec["lxc-bootstrap ${instance}"],
          Exec["systemd reload for ${service}"],
        ],
      }
    }

    absent: {
      file { $service_file:
        ensure => absent,
      }

      service { $service:
        ensure => stopped,
        enable => false,
        before => Exec["rm -rf \"${rootfs}\""],
      }
    }

    default: {
      fail("lxc::host::archlinux doesn't support ensure => ${ensure}")
    }
  }
}
