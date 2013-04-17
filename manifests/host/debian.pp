# == Class: lxc::host::debian
#
# This class prepares a debian host for running containers. You do not have
# to include this class yourself.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
class lxc::host::debian {
  package { 'lxc':
    ensure => installed,
  }

  # Set RUN to yes in /etc/defaults/lxc so the lxc init script will start
  # the configured containers at boot
  augeas { 'lxc enable':
    context => '/files/etc/default/lxc',
    changes => [
      'set RUN yes',
    ],
    require => Package['lxc'],
  }

  # lxc on debian is not really a service, just a launcher. So it doesn't
  # have to be started. We start the container in lxc::host::debian::service
  service { 'lxc':
    ensure  => stopped,
    enable  => true,
    require => Package['lxc'],
  }
}
