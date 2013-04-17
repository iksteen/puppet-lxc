# == Resource: lxc::container::bootstrap
#
# This resource is resposible for calling the bootstrap script and the
# destruction of a container. You should never have to create an instance
# unless you are developing a new template.
#
# === Parameters
#
# [*ensure*]
#   Specify the state the container should be in. Either running, stopped
#   or absent.
#
# [*instance*]
#   The instance name of the container. Defaults to $title.
#
# [*template*]
#   Specify the filename of the lxc config template to use.
#
# [*ipaddress*]
#   Specify the IP address the container should use. Note that you can't
#   change this after the container has been bootstrapped.
#
# [*rootfs*]
#   Specify the path where the root filesystem will be created. The default
#   is ${lxc::rootfs_home}/${instance}.
#
# [*puppetserver*]
#   Specify the puppet server to preconfigure the container to connect to.
#
# [*fqdn*]
#   Specify the fqdn to preconfigure the container to use. Defaults to
#   ${instance}.${::domain}.
#
# [*command*]
#   Specify the command to execute to bootstrap the container. Required when
#   ensure is running or stopped.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
define lxc::container::bootstrap(
    $ensure,
    $template,
    $ipaddress,
    $rootfs,
    $puppetserver,
    $instance     = $title,
    $fqdn         = undef,
    $command      = undef,
) {
  $config     = "/etc/lxc/${instance}.conf"

  include lxc

  $rootfs_real = $rootfs ? {
    undef   => "${lxc::rootfs_home}/${instance}",
    default => $rootfs,
  }

  $fqdn_real = $fqdn ? {
    undef   => "${instance}.${::domain}",
    default => $fqdn,
  }

  lxc::host::service { $instance:
    ensure => $ensure,
    rootfs => $rootfs_real,
    config => $config,
  }

  case $ensure {
    /^(running|stopped)$/: {
      if $command == undef {
        fail("lxc::container::bootstrap with ensure => ${ensure} requires command")
      }

      file { $config:
        ensure  => file,
        mode    => '0644',
        owner   => root,
        group   => root,
        content => template($template),
      }

      exec { "lxc-bootstrap ${instance}":
        command     => $command,
        environment => [
          "lxc_instance=${instance}",
          "lxc_config=${config}",
          "lxc_rootfs=${rootfs_real}",
          "lxc_hostname=${fqdn_real}",
          "lxc_ipaddress=${ipaddress}",
          "lxc_netmask=${lxc::bridge::netmask}",
          "lxc_gateway=${lxc::bridge::ipaddress}",
          "lxc_puppetserver=${puppetserver}",
        ],
        timeout     => 0,
        creates     => $rootfs_real,
        require     => File[$config],
      }
    }

    absent: {
      file { $config:
        ensure => absent,
      }

      exec { "rm -rf \"${rootfs_real}\"":
        onlyif => "test -d \"${rootfs_real}\"",
        path   => ["/bin", "/usr/bin"],
      }
    }

    default: {
      fail("lxc::container::bootstrap does not support ensure => ${ensure}")
    }
  }
}
