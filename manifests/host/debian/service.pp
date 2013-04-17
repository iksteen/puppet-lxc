# == Resource: lxc::host::debian::service
#
# This resource ensures the create, deletion, starting, stopping and
# enabled state of services that control a container on a Debian host
# platform. It is used internally and you should never have to create
# an instance yourself.
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
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
define lxc::host::debian::service(
    $ensure,
    $instance = $title,
) {
  if $::operatingsystem != debian {
    fail("lxc::host::debian not supported on ${::operatingsystem}")
  }

  case $ensure {
    running: {
      # Enable the container in /etc/lxc/lxc.conf so it gets started at boot
      augeas { "lxc container ${instance}":
        lens    => 'Shellvars_list.lns',
        incl    => '/etc/default/lxc',
        changes => [
          "set CONTAINERS/value[ .= '${instance}' ] '${instance}'",
        ],
      }

      # If the container was added using augeas, start the container
      exec { "/usr/bin/lxc-start -n ${instance} -f /etc/lxc/${instance}.conf -d":
        subscribe   => Augeas["lxc container ${instance}"],
        refreshonly => true,
      }
    }

    /^(stopped|absent)$/: {
      # Disable the container in /etc/lxc/lxc.conf
      augeas { "lxc container ${instance}":
        lens    => 'Shellvars_list.lns',
        incl    => '/etc/default/lxc',
        changes => [
          "rm CONTAINERS/value[ .= '${instance}' ]",
        ],
      }

      # If the container was removed using augeas, stop the container
      exec { "/usr/bin/lxc-stop -n ${instance}":
        subscribe   => Augeas["lxc container ${instance}"],
        refreshonly => true,
      }
    }

    default: {
      fail("lxc::host::debian doesn't support ensure => ${ensure}")
    }
  }
}
