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
define lxc::host::debian::service(
    $ensure,
    $rootfs,
    $config,
    $instance = $title,
) {
  if $::operatingsystem != debian {
    fail("lxc::host::debian not supported on ${::operatingsystem}")
  }

  case $ensure {
    running: {
      case $::lsbdistcodename {
        squeeze: {
          # Enable the container in /etc/lxc/lxc.conf so it gets started at boot
          augeas { "lxc container ${instance}":
            lens    => 'Shellvars_list.lns',
            incl    => '/etc/default/lxc',
            changes => [
              "set CONTAINERS/value[ .= '${instance}' ] '${instance}'",
            ],
          }
          # If the container was added using augeas, start the container
          exec { "/usr/bin/lxc-start -n ${instance} -f ${config} -d":
            refreshonly => true,
            subscribe   => Augeas["lxc container ${instance}"],
          }
        }
        wheezy: {
          # Symlink the container config to auto so it gets stated at boot
          # Note: This is a bit of a hack, we basically emulate lxc-create
          file { "/var/lib/lxc/${instance}":
            ensure => directory,
          }
          file { "/var/lib/lxc/${instance}/config":
            ensure  => file,
            source  => "/etc/lxc/${instance}.conf",
            require => File["/etc/lxc/${instance}.conf"],
          }
          file { "/var/lib/lxc/${instance}/rootfs":
            ensure => link,
            target => $rootfs,
          }
          file { "/etc/lxc/auto/${instance}":
            ensure => link,
            target => "/var/lib/lxc/${instance}/config",
          }
          # If the container was symlinked, start the container
          exec { "/usr/bin/lxc-start -n ${instance} -f /etc/lxc/auto/${instance} -d":
            refreshonly => true,
            subscribe   => File["/etc/lxc/auto/${instance}"],
          }
        }
        default: {
          fail("lxc::host::debian::service not supported on ${::lsbdistcodename}")
        }
      }
    }

    /^(stopped|absent)$/: {
      case $::lsbdistcodename {
        squeeze: {
          # Disable the container in /etc/lxc/lxc.conf
          augeas { "lxc container ${instance}":
            lens    => 'Shellvars_list.lns',
            incl    => '/etc/default/lxc',
            changes => [
              "rm CONTAINERS/value[ .= '${instance}' ]",
            ],
          }

          # If the container was removed using augeas, stop the container
          exec { "/usr/bin/lxc-stop -n \"${instance}\"":
            refreshonly => true,
            subscribe   => Augeas["lxc container ${instance}"],
          }
        }
        wheezy: {
          # Remove lxc support files
          file { "/etc/lxc/auto/${instance}":
            ensure => absent,
          }

          # If the container symlink removed, stop the container
          exec { "/usr/bin/lxc-stop -n \"${instance}\"":
            refreshonly => true,
            subscribe   => File["/etc/lxc/auto/${instance}"],
          }
          
          if $ensure == absent {
            file { "/var/lib/lxc/${instance}":
              ensure => absent,
            }
          }
        }
        default: {
          fail("lxc::host::debian::service not supported on ${::lsbdistcodename}")
        }
      }

      if $ensure == absent {
        Exec["/usr/bin/lxc-stop -n \"${instance}\""] -> Exec["rm -rf \"${rootfs}\""]
      }
    }

    default: {
      fail("lxc::host::debian doesn't support ensure => ${ensure}")
    }
  }
}
