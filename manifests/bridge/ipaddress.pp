# == Resource: lxc::bridge::ipaddress
#
# This resource is used by the container bootstrapper to prevent doubly
# allocated IP addresses and checks if the container IP address is contained
# by the bridge network.
#
# === Parameters
#
# [*ipaddress*]
#   The IP address to allocate. Defaults to $title.
#
# === Authors
#
# Ingmar Steen <iksteen@gmail.com>
#
# === Copyright
#
# Copyright 2013 Ingmar Steen, unless otherwise noted.
#
define lxc::bridge::ipaddress($ipaddress=$title) {
  $bridge_ip = $lxc::bridge::ipaddress
  $bridge_nm = $lxc::bridge::netmask

  unless is_ip_in_range($bridge_ip, $bridge_nm, $ipaddress) {
    fail("bridge network ${bridge_ip}/${bridge_nm} does not contain ip address ${ipaddress}")
  }
}